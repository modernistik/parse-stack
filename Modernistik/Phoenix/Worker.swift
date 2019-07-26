//
//  Worker.swift
//  Modernistik
//
//  Created by Anthony Persaud on 5/15/17.
//

import Foundation

open class Worker: Operation {
    
    
    @discardableResult
    open class func rekindle(task: Phoenix.WorkItem) -> Worker {
        let op = self.init()
        op.task = task
        op.restored()
        op.queue.addOperation(op)
        return op
    }
    
    @discardableResult
    open class func restore(task: Phoenix.WorkItem) -> Worker {
        let op = self.init()
        op.task = task
        op.isRestored = true
        op.restored()
        op.queue.addOperation(op)
        return op
    }
    
    @discardableResult
    open class func enqueue(params: [String:Any]? = nil) -> Self  {
        let op = self.init()
        if let params = params {
            op.params = params
        }
        op.configure()
        op.queue.addOperation(op)
        return op
    }
    
    public enum Status: String {
        case unknown, success, failed, retrying
    }
    
    // MARK: - Types
    public enum State {
        case ready, executing, finished
        var keyPath: String {
            switch self {
            case .ready:
                return "isReady"
            case .executing:
                return "isExecuting"
            case .finished:
                return "isFinished"
            }
        }
    }
    
    public var workerClass: String { return NSStringFromClass( type(of: self) ) }
    public var tid = UUID().uuidString
    public var params = [String:Any]()
    public var queue: OperationQueue { return Phoenix.queue }
    public var created = Date()
    public var data = [String:Any]()
    public var result: Any?
    public var isRestored: Bool = false
    public var dependencyIds = [String]()
    public var failureError: Error?
    public var maxRetries = Int.max
    public var retries = 0
    public var status = Status.unknown
    
    public required init(task: Phoenix.WorkItem? = nil) {
        super.init()
        qualityOfService = .background
        if let task = task {
            self.task = task
        }
        
        if self.name == nil {
            self.name = "\(workerClass):\(tid)"
        }
    }
    
    // MARK: - Properties
    
    open var state = State.ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
    
    func restoreDependencies(_ workers: [Worker]) {
        dependencyIds.forEach { (taskId) in
            if let found = workers.first(where: { $0.tid == taskId }) {
                log("Restoring dependency: \(found.tid) - \(tid)")
                addDependency(found)
            } else {
                log("Worker Dependency \(taskId) - not found.")
            }
        }
    }
    
    func updateDependencyList() {
        guard dependencies.count > 0 else { return }
        
        var ids = [String]()
        for op in dependencies {
            if let op = op as? Worker {
                ids.append(op.tid)
            }
        }
        dependencyIds = ids
    }
    
    override public final func start() {
        if self.isCancelled {
            state = .finished
        } else {
            before()
            state = .executing
            Phoenix.postNotification(name: .PhoenixOperationStarted, worker: self)
            Phoenix.postNotification(name: .PhoenixOperationQueueDidChange, worker: self)
            main()
            // if the worker has been marked as non-async
            // call completed when main returns.
            if isAsynchronous == false {
                completed()
            }
        }
    }
    
    // MARK: - NSOperation
    
    override open var isReady: Bool {
        return super.isReady && state == .ready
    }
    
    override open var isExecuting: Bool {
        return state == .executing
    }
    
    override open var isFinished: Bool {
        return state == .finished
    }
    
    override open var isAsynchronous: Bool {
        return true
    }
    
    /// Override this method to perform work, but do not call `super`. Work can be synchronous or
    /// asynchronous, however your implementation should call `completed()` when you can declare
    /// the task as finished.
    override public final func main() {
        log("Started")
        work()
    }
    
    public final func retry() {
        guard retries < maxRetries else { return failed(PhoenixError.maxRetriesExceeded) }
        retries += 1
        let additionalSeconds:TimeInterval = min(pow(2.0, Double(retries) ) , 15)
        let deadline = DispatchTime.now() + additionalSeconds
        self.status = .retrying
        log("Retrying in \(additionalSeconds) seconds.")
        DispatchQueue.global().asyncAfter(deadline: deadline) {
            self.main()
        }
    }
    
    open func enqueue() {
        if state == .ready {
            updateDependencyList()
            configure()
            queue.addOperation(self)
        } else {
            assertionFailure("\(type(of: self)): You may not call `enqueue` directly.")
        }
    }
    
    /// Call this function after any work is done or after a call to `cancel()`
    /// to move the operation into a completed state.
    public final func completed() {
        guard state != .finished else { return }
        status = .success
        state = .finished
        Phoenix.postNotification(name: .PhoenixOperationFinished, worker: self)
        Phoenix.postNotification(name: .PhoenixOperationQueueDidChange, worker: self)
        after()
    }
    
    /// Call this function after any work is done or after a call to `cancel()`
    /// to move the operation into a completed state.
    public final func failed(_ error:Error? = nil) {
        guard state != .finished else { return }
        if let error = error {
            err("Failed: \(error.localizedDescription)")
            self.failureError = error
        } else {
            self.failureError = PhoenixError.failed
        }
        status = .failed
        state = .finished // to allow notifications to go out
        Phoenix.postNotification(name: .PhoenixOperationFinished, worker: self)
        Phoenix.postNotification(name: .PhoenixOperationQueueDidChange, worker: self)
        after()
    }
    
    /// This method is called before the worker is enqueued
    open func configure() { }
    
    /// Called when the task has been restored from the persistent store and about to be enqueued agian.
    open func restored() {}
    
    /// This method will be called before the worker moves to the executing state and begins the work.
    open func before() {}
    
    /// Override this method to perform work. Work can be synchronous or
    /// asynchronous, however your implementation should call `completed()` when you can declare
    /// the task as finished.
    open func work() { }
    
    /// This method will be called after the worker has completed and has moved to the finished state.
    open func after() {}
    
    final public func log(_ message:String) {
        print("Ⓜ️[\(workerClass))-\(tid)]: \(message)")
    }
    final public func err(_ message:String) {
        print("🔴[\(workerClass))-\(tid)]: Error - \(message)")
    }
}

extension Worker {
    
    // Might want to switch to using Unbox/Wrap with a Struct
    // Swift 4 will have Codable protocol available.
    open var task: Phoenix.WorkItem {
        get {
            updateDependencyList()
            return [
                "tid" : tid,
                "workerClass": workerClass,
                "queuePriority": queuePriority.rawValue,
                "params": params,
                "created": created,
                "data": data,
                "retries": retries,
                "deps": dependencyIds
            ]
        }
        set {
            self.tid = newValue["tid"] as? String ?? UUID().uuidString
            self.name = "\(workerClass):\(tid)"
            if let priorityValue = newValue["queuePriority"] as? Int,
                let priority = Operation.QueuePriority(rawValue: priorityValue) {
                queuePriority = priority
            }
            
            if let p = newValue["params"] as? [String:Any] {
                params = p
            }
            
            if let d = newValue["data"] as? [String:Any] {
                data = d
            }
            
            if let date = newValue["created"] as? Date {
                created = date
            }
            if let list =  newValue["deps"] as? [String] {
                dependencyIds = list
            }
            self.retries = newValue["retries"] as? Int ?? 0
        }
    }
}


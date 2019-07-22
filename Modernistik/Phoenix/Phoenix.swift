//
//  Phoenix.swift
//  Modernistik
//
//  Created by Anthony Persaud on 5/15/17.
//
//  Copyright © Modernistik LLC. All rights reserved.

import Foundation

public protocol PhoenixPersistence {
    func serializeTasks(_ tasks:[Phoenix.WorkItem], phoenix:Phoenix)
    func deserializeTasks(phoenix:Phoenix) -> [Phoenix.WorkItem]
}

public class UserDefaultsPhoenixStore : PhoenixPersistence {

    public func serializeTasks(_ tasks: [Phoenix.WorkItem], phoenix: Phoenix) {
        UserDefaults.standard.set(tasks, forKey: Phoenix.queueName)
        UserDefaults.standard.synchronize()
        print("Phoenix ---- ")
        for task in tasks {
            if let name = task["workerClass"] as? String, let tid = task["tid"] as? String {
                print("✅ Phoenix: \(name) - \(tid)")
            }
        }
    }

    public func deserializeTasks(phoenix: Phoenix) -> [Phoenix.WorkItem] {
        if let tasks = UserDefaults.standard.array(forKey: Phoenix.queueName) as? [Phoenix.WorkItem] {
            return tasks
        }
        return [Phoenix.WorkItem]()
    }
}

extension Notification.Name {
   public static let PhoenixOperationQueueDidChange = Notification.Name("PhoenixOperationQueueDidChange")
   public static let PhoenixOperationStarted = Notification.Name("PhoenixOperationStarted")
   public static let PhoenixOperationFinished = Notification.Name("PhoenixOperationFinished")
}



public enum PhoenixError: Error {
    case failed, maxRetriesExceeded
    
    var localizedDescription: String {
        switch self {
        case .failed:
            return "The worker failed to complete task."
        case .maxRetriesExceeded:
            return "The worker exceeded the number of maximum retries."
        }
    }
}


open class Phoenix : NSObject {

    public typealias WorkItem = [String:Any]
    public static let queueName = "Phoenix:queue"
    // Can't init is singleton
    private static let syncQueue = DispatchQueue(label: "com.phoenixqueue.sync")
    private override init() { }
    public static let shared = Phoenix()
    var backgroundTask = UIBackgroundTaskIdentifier.invalid
    public static var autoResume = true
    public static var snapshotInterval: TimeInterval = 10
    private var snapshotTimer: Timer?
    public static var serializer: PhoenixPersistence = UserDefaultsPhoenixStore()

    public static var queue: OperationQueue = {
        let q =  OperationQueue()

        NotificationCenter.default.addObserver(Phoenix.shared, selector: #selector(Phoenix.didTerminate(note:)), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(Phoenix.shared, selector: #selector(Phoenix.didBecomeActive(note:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        q.addObserver(shared, forKeyPath: #keyPath(OperationQueue.operationCount), options: [.old, .new], context: nil)
        return q
    }()
    public static var activeTasks: [WorkItem] {
        var tasks = [WorkItem]()
        for op in queue.operations
            where op.isFinished == false && op.isCancelled == false {

                if let op = op as? Worker {
                    let task = op.task
                    tasks.append(task)
                }
        }
        return tasks
    }
    public static func clearAll() {
        queue.cancelAllOperations()
        serializer.serializeTasks([], phoenix: shared)
    }
    public static func postNotification(name:Notification.Name, worker:Worker) {
        async_main {
            NotificationCenter.default.post(name: name, object: worker)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(Phoenix.shared)
    }

    private static var hasLaunched: Bool = false

    /// Starts the system
    open class func start() {
        if self.hasLaunched == false {
            self.hasLaunched = true
            resume()
            rekindle()
        }
    }

    open class func shutdown() {
        queue.isSuspended = true
        freeze()
    }

    open class func resume() {
        Phoenix.queue.isSuspended = false
    }

    @objc open func didBecomeActive(note:Notification) {
        if Phoenix.autoResume {
            Phoenix.resume()
        }
    }

    @objc open func didTerminate(note:Notification) {
        Phoenix.shutdown()
    }

    class public func rekindle() {
        let tasks = serializer.deserializeTasks(phoenix: shared)
        var ops = [Worker]()
        for task in tasks {
            if let workerClass = task["workerClass"] as? String,
                let klass = NSClassFromString(workerClass) as? Worker.Type {
                let op = klass.init(task: task)
                ops.append(op)
                print("Rekindling :\(op.tid)")
            }
        }
        /// Now that the operations have been unthawed, let's rebuild the dependency graph
        for op in ops {
            op.restoreDependencies(ops)
            op.restored()
            op.isRestored = true
            op.enqueue()
        }
    }

    class open func freeze() {
        Phoenix.serializer.serializeTasks(Phoenix.activeTasks, phoenix: shared)
    }

    @objc public func updateActiveTasks() {
        let app = UIApplication.shared
        Phoenix.freeze()
        /// if no tasks in queue, the end background task
        if Phoenix.queue.operationCount == 0 && backgroundTask != .invalid {
            app.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        } else if backgroundTask == .invalid {
            backgroundTask = app.beginBackgroundTask { [weak self] in
                Phoenix.shutdown()
                if let backgroundTask = self?.backgroundTask {
                    app.endBackgroundTask(backgroundTask)
                    self?.backgroundTask = .invalid
                }
            }
        }

        // if the app is in the background, and we have less than 30 seconds, stop the queue from starting new workers.
        if app.applicationState == .background && app.backgroundTimeRemaining < 30 {
            Phoenix.queue.isSuspended = true
        }
    }

    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(OperationQueue.operationCount) {
            if Phoenix.queue.operationCount == 0 {
                async_main { [weak self] in
                    self?.snapshotTimer?.invalidate()
                    self?.snapshotTimer = nil
                    self?.updateActiveTasks()
                }

            } else if snapshotTimer == nil {
                // Timers need to be created on the main thread.
                async_main { [weak self] in
                    self?.updateActiveTasks()
                    self?.snapshotTimer?.invalidate()
                    self?.snapshotTimer = Timer.scheduledTimer(withTimeInterval: Phoenix.snapshotInterval, repeats: true, block: { [weak self] (timer) in
                        print("Background time remaining = \(UIApplication.shared.backgroundTimeRemaining) seconds")
                        self?.updateActiveTasks()
                    })
                }
            }
        }
    }
}

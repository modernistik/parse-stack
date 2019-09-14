//
//  Modernistik
//  Copyright © Modernistik LLC. All rights reserved.
//

import Foundation

/// A callback block for ConcurrentOperation instances that allow you to add simple block-based tasks that have asynchronous code. To use, call `finish()` whenever the task you were performing is completed.
public typealias ConcurrentOperationBlock = (_ finish: @escaping (CompletionBlock)) -> Void
/**
 A useful Operation subclass that allows for asynchrnous
 actions to be performed before being marked as completed.

 To use, you sublcass `ConcurrentOperation`, override
 `main()` and call `finish()` whenever you want to mark the
 operation as completed.

 ## Subclassing Example
 ````
 public class SampleOperation : ConcurrentOperation {

    override open func main() {

        //... do some async work.
        async_delay(3) {

            // call when done
            self.finish()
        }
    }
 }
 ````

 For small tasks, may also use the block based approach instead of subclassing:

  ## Block Example
  ````
 let op =  ConcurrentOperation { (finish) in
    async_background {
    // .. do some async work
    // when done, call finish()
        finish()
    }
 }
 queue.addOperation(op)
  ````
 - note: Do not call `super.main()` in your implementation.
 */
open class ConcurrentOperation: Operation {
    public lazy var finishCallback: CompletionBlock = { { self.finish() } }()
    public var task: ConcurrentOperationBlock?

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

    open override func start() {
        if isCancelled {
            state = .finished
        } else {
            state = .executing
            main()
        }
    }

    open override var isReady: Bool {
        return super.isReady && state == .ready
    }

    open override var isExecuting: Bool {
        return state == .executing
    }

    open override var isFinished: Bool {
        return state == .finished
    }

    open override var isAsynchronous: Bool {
        return true
    }

    public convenience init(task: @escaping ConcurrentOperationBlock) {
        self.init()
        self.task = task
    }

    /// Override this method to perform work, but do not call `super`. Work can be synchronous or
    /// asynchronous, however your implementation should call `completed()` when you can declare
    /// the task as finished.
    open override func main() {
        if let task = task {
            task(finishCallback)
            return
        }
        assertionFailure("\(type(of: self)): Subclasses must implement `main` and call `finish()` when done. Do not call super in your implementation.")
        finish()
    }

    /// Call this function after any work is done or after a call to `cancel()`
    /// to move the operation into a completed state.
    public final func finish() {
        state = .finished
    }
}

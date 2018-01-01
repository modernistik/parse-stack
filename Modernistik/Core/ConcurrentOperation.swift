//
//  Modernistik
//  Copyright © Modernistik LLC. All rights reserved.
//

import Foundation
/**
 A useful Operation subclass that allows for asynchrnous
 actions to be performed before being marked as completed.
 
 To use, you sublcass `ConcurrentOperation`, define override
 `main()` and call `finish()` whenever you want to mark the
 operation as completed.
 
 ## Example
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
*/
open class ConcurrentOperation: Operation {

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
  
        if self.isCancelled {
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

    /// Override this method to perform work, but do not call `super`. Work can be synchronous or
    /// asynchronous, however your implementation should call `completed()` when you can declare
    /// the task as finished.
    override open func main() {
        assertionFailure("\(type(of: self)): Subclasses must implement `main` and call `finish()` when done. Do not call super class.")
        finish()
    }

    /// Call this function after any work is done or after a call to `cancel()`
    /// to move the operation into a completed state.
    public final func finish() {
        state = .finished
    }
}




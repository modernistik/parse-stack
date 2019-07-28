//
//  Modernistik
//  Copyright © Modernistik LLC. All rights reserved.
//

import Foundation

/// A basic empty completion block that provides an error in case of failure.
/// - parameter error: An error if not successful.
public typealias CompletionResultBlock = (_ error:Error?) -> Void
public typealias ResultBlock = CompletionResultBlock

/// A completion block that returns a boolean result.
/// - parameter success: A boolean result whether it was completed successfully.
public typealias CompletionSuccessBlock = (_ success:Bool) -> Void
public typealias SuccessBlock = CompletionSuccessBlock

/// A completion block that returns a boolean result and a possible error.
/// - parameter success: A boolean result whether it was completed successfully.
/// - parameter error: An error if not successful.
public typealias CompletionBooleanBlock = (_ success:Bool, _ error:Error?) -> Void

/// A basic completion block with no parameters or result.
public typealias CompletionBlock = () -> Void

// MARK: NSBundle
extension Bundle {
    
    /// Returns the current build version based on the `CFBundleVersion` of the Info.plist. Defaults 0.
    public static var releaseVersion:String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
    
    /// Returns the current build version based on the `CFBundleVersion` of the Info.plist. Defaults 0.
    public static var currentBuildVersion:Int {
        if let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String,
            let buildNumber = Int(buildVersion) {
                return buildNumber
        }
        return 0
    }
    
}

// MARK: Array NSLayoutConstraint extensions
extension Array where Element: NSLayoutConstraint {
    /// Activates an array of NSLayoutConstraints
    public func activate() {
        NSLayoutConstraint.activate(self)
    }
    
    /// Deactivates an array of NSLayoutConstraints
    public func deactivate() {
        NSLayoutConstraint.deactivate(self)
    }
    
}

extension Array {
    /// Returns true if index is inRange of 0 and the array's last index.
    public func has(index: Int) -> Bool {
        return index >= 0 && index.inRange(0, lastIndex)
    }
}

extension String {
    /// Uses the string as a NSLayoutConstraint visual format specification for constraints. For more information,
    /// see Auto Layout Cookbook in Auto Layout Guide.
    /// - parameter opts: Options describing the attribute and the direction of layout for all objects in the visual format string.
    /// - parameter metrics: A dictionary of constants that appear in the visual format string. The dictionary’s keys must be the string
    ///   values used in the visual format string. Their values must be NSNumber objects.
    /// - parameter views: A dictionary of views that appear in the visual format string. The keys must be the string values used in the visual format string, and the values must be the view objects.
    /// - returns: An array of NSLayoutConstraints that were parsed from the string.
    public func constraints(options opts: NSLayoutConstraint.FormatOptions = [], metrics: [String : Any]? = nil, views: [String : Any]) -> [NSLayoutConstraint] {
        // NOTE: If you exception breakpoint hits here, go back one call stack to see the constraint that is causing the error.
        return NSLayoutConstraint.constraints(withVisualFormat: self, options: opts, metrics: metrics, views: views)
    }
    
    /// Uses the string as a NSLayoutConstraint visual format with no options or metrics.
    /// - parameter opts: Options describing the attribute and the direction of layout for all objects in the visual format string.
    /// - parameter views: A dictionary of views that appear in the visual format string. The keys must be the string values used in the visual format string, and the values must be the view objects.
    /// - returns: An array of NSLayoutConstraints that were parsed from the string.
    public func constraints(options opts: NSLayoutConstraint.FormatOptions, views: [String : Any]) -> [NSLayoutConstraint] {
        // NOTE: If you exception breakpoint hits here, go back one call stack to see the constraint that is causing the error.
        return NSLayoutConstraint.constraints(withVisualFormat: self, options: opts, metrics: nil, views: views)
    }
}

extension URL {
    /// Returns true if the url is a file path and if it exists in the local file system.
    public var fileExists: Bool {
        return isFileURL && FileManager.default.fileExists(atPath: path)
    }
}


extension FileManager {
    /// Returns the documents directory for the default file manager
    public static var documentsDirectory:URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// Returns the caches directory for the default file manager
    public static var cachesDirectory: URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    public static func directory(for directory:FileManager.SearchPathDirectory) -> URL {
        return FileManager.default.urls(for: directory, in: .userDomainMask).first!
    }
}

// MARK: NSUserDefaults
extension UserDefaults {
    
    /**
    Sets true to the given key in NSUserDefaults. If the value has not been
     previously flagged this method returns true. If it has been previously flagged it returns false.
    
    Assume you want to run some code that should only happen once, you can do
     the following:
    ````
     let key = "ShouldShowOneTimePopUp"
     
     if UserDefaults.flagOnce(forKey: key) {
       // show one-time popup
     }
     
     // this will now return false
     UserDefaults.flagOnce(forKey: key) // => false
     
    ````
    - parameter key: The NSUserDefaults string key name to use for storing the flag.
    - returns: true if the flag was successfully created or changed from false to true.
     */
    public class func flagOnce(forKey key:String) -> Bool {
        let d = standard
        var flagged = false //only flag if we've never flagged before.
        
        if d.object(forKey: key) == nil || d.bool(forKey: key) == false {
            flagged = true
            d.set(true, forKey: key)
            d.synchronize()
        }
        
        return flagged;
        
    }
    
    /// Sets false to the NSUserDefaults key provided. This basically resets the flag state.
    ///
    /// - parameter key: The NSUserDefaults string key name.
    public class func resetFlag(forKey key:String) {
        standard.removeObject(forKey: key)
        standard.synchronize()
    }
    
}

/// A short macro to perform an `dispatch_async` (main thread) at a later time in seconds, using the `dispatch_after` call.
///
/// - parameter seconds: The number of seconds to wait before performing the closure
/// - parameter closure: A void closure to perform at a later time on the main thread.
public func async_delay(_ seconds:Double, closure: @escaping CompletionBlock) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: closure)
}

/// Dispatch a block on the main queue.
///
/// - parameter closure: The closure to execute on the main thread.
public func async_main(_ closure: @escaping CompletionBlock ) {
    DispatchQueue.main.async(execute: closure)
}

/// Dispatch a block in the background queue
///
/// - parameter closure: The closure to execute on the background thread.
@available(*, deprecated, renamed: "dispatch(_:closure:)", message: "This method has been renamed.")
public func async_background(_ closure: @escaping CompletionBlock ) {
    DispatchQueue.global(qos: .background).async(execute: closure)
}

/// Dispatch a block with in the background using a specified quality of service.
/// ```
///   dispatch(.background) {
///      // do some work in the background queue...
///   }
///
///   dispatch(.userInteractive) {
///      // do some work on the main thread.
///   }
/// ```
/// - note: To use dispatch a block to the main thread, use `.userInteractive`
/// - parameter qos: The quality of service class to use. Defaults to `.default`.
/// - parameter closure: The closure to execute.
public func dispatch(_ qos: DispatchQoS.QoSClass = .default, closure: @escaping CompletionBlock ) {
    DispatchQueue.global(qos: qos).async(execute: closure)
}

extension CFTimeInterval {
    /// Returns the absolute current time.
    public static var currentTime: CFTimeInterval  {
        return CFAbsoluteTimeGetCurrent()
    }
    /// The amount of time that has lapsed up to 3 decimal places
    /// using this value as an absolute time interval.
    public var timeLapsed: CFTimeInterval {
        return (CFAbsoluteTimeGetCurrent() - self).roundTo(3)
    }
}

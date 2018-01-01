//
//  Modernistik
//  Copyright © 2016 Modernistik LLC. All rights reserved.
//

import Parse

/// Alias to block type `PFIdResultBlock` with signature `(result,error)`.
public typealias FunctionResultBlock = PFIdResultBlock

/// Alias for `[String: Any]`
public typealias Params  = [String:Any]

/**
 Protocol that defines an clean interface with interacting with Modernistik Hyperdrive server.
 It is recommended for classes that will encapsulate the SDK connecting to the server to implement
 this protocol.
 ## Example
 ````
 class MyAppServer : Hyperdrive {
    enum Function: String {
        case helloWorld
        case myCloudCodeMethodName
        // ... other methods listed here.
    }
 }
 ````

 Doing so will allow the extensions to Hyperdrive to be applied to your class providing a
 standard interface to making API calls. You can then connect and setup the stack by calling the method
 `setup` and, if needed, set any default `ACLs` for created objects.

 ````
 // Connect
 MyAppServer.setup(
        serverUrl:"<server_url>",
    applicationId:"<app id>,
        clientKey:"<client id>")


 // optional: Set default public acls
 MyAppServer.setupDefaultPublicACL(
            read: true, write: false
 )

 // optional: Fetch config when app becomes active
 MyAppServer.updateConfiguration()
 ````
 Those methods should be called early in the launch of your `UIApplicationDelegate`.
*/
public protocol Hyperdrive {
    /// An enum type for implementors of the Hyperdrive protocol that should list all cloud function names.
    /// It is highly recommended for this to be of type `String`.
    associatedtype Function: RawRepresentable

    /// A **synchronous** API to call a cloud function.
    ///
    /// - Parameter function: The name of the function.
    /// - Parameter params: The parameters to send to the function.
    /// - Returns: The result of the function.
    /// - Throws: The server error that was returned.
    static func call(function: String, with params: Params?) throws -> Any

    /// An **asynchronous** API to call a cloud function.
    ///
    /// - Parameter function: The name of the function.
    /// - Parameter params: The parameters to send to the function.
    /// - Parameter block: The block to execute when the function call finished. It should have the following argument signature: `(result,error)`.
    static func callInBackground(function: String, with params: Params?, block: FunctionResultBlock?)

    /**
     The method to call to initiate configuration and connection to the Hyperdrive server.

     - Parameter serverUrl: The server url of the Hyperdrive server. (ex. http://localhost:1337/parse)
     - Parameter applicationId: The application id defined on the server.
     - Parameter clientKey: The client key defined on the server.
     */
    static func setup(serverUrl:String, applicationId:String, clientKey:String)

    /// Method to fetch updated configuration (Parse Config) from the server. If successful, it
    /// will send a `HyperdriveConfigUpdatedNotification` notification.
    ///
    /// - Parameter completion: A completion handler when the fetch has been completed.
    static func updateConfiguration(completion:ResultBlock?)
}

extension Hyperdrive where Function.RawValue == String {

    /**
    A **synchronous** API to call a cloud function.
     ## Example

     ````
     class MyAppServer : Hyperdrive {
        enum Function: String {
            case helloWorld
        }
     }

     let params = ["key":"value"]

     MyAppServer.call(function: .helloWorld, with: params)
     ````

    - Parameter function: One of the `Function` enums defined in your Hyperdrive class.
    - Parameter params: The parameters to send to the function.
    - Returns: The result of the function.
    - Throws: The server error that was returned.
    */
    @discardableResult
    public static func call(function: Function, with params: Params? = nil) throws -> Any {
        return try PFCloud.callFunction(function.rawValue, withParameters: params)
    }

    /**
     A **asynchronous** API to call a Hyperdrive cloud function.
     ## Example

     ````
     class MyAppServer : Hyperdrive {
        enum Function: String {
            case helloWorld
        }
     }

     let params = ["key":"value"]

     MyAppServer.callInBackground(function: .helloWorld, with: params) { (result, error) in
        // handle result or error
     }
     ````

     - Parameter function: One of the `Function` enums defined in your Hyperdrive class.
     - Parameter params: The parameters to send to the function.
     - Parameter block: The block to execute when the function call finished. It should have the following argument signature: `(result,error)`.
     */
    public static func callInBackground(function: Function, with params: Params? = nil, block: FunctionResultBlock?) {
        PFCloud.callFunction(inBackground: function.rawValue, withParameters: params, block: block)
    }
}

extension Hyperdrive {

    /// Returns the config value based on the key.
    ///
    /// - Parameter key: The name of the configuration key.
    /// - Returns: The value for this key if any.
    public static func config(_ key:String) -> Any? {
        return PFConfig.current().object(forKey: key)
    }

    /// Method to fetch updated configuration (Parse Config) from the server. If successful, it
    /// will send a `HyperdriveConfigUpdatedNotification` notification.
    ///
    /// - Parameter completion: A completion handler when the fetch has been completed.
    public static func updateConfiguration(completion:ResultBlock? = nil) {
        PFConfig.getInBackground { (config, error) -> Void in
            completion?(error)
            guard error == nil else { return }
            NotificationCenter.default.post(name: .HyperdriveConfigUpdatedNotification, object: config, userInfo: nil)
        }
    }

    /// Clears all results for queries that have been cached.
    public static func clearCaches() {
        PFQuery.clearAllCachedResults()
    }

    /**
    The method to call to initiate configuration and connection to the Hyperdrive server. It will also
    automatically enable revocable sessions in background.

    - Parameter serverUrl: The server url of the Hyperdrive server. (ex. http://localhost:1337/parse)
    - Parameter applicationId: The application id defined on the server.
    - Parameter clientKey: The client key defined on the server.
    */
    public static func setup(serverUrl:String, applicationId:String, clientKey:String) {

        let configuration = ParseClientConfiguration {
            $0.server = serverUrl
            $0.applicationId = applicationId
            $0.clientKey = clientKey
            PFUser.enableRevocableSessionInBackground()

        }
        Parse.initialize(with: configuration)
    }

    /**
     Sets the default public (global) and user read/write priviledges when
     the app or user creates new objects.

     - Parameter read: The default public read ACL to give new objects.
     - Parameter write: The default public write ACL to give new objects.
     - Parameter currentUserAccess: If `true` (default), the ACL that is applied to
     newly-created Parse objects will provide read and write access to the current
     logged in user at the time of creation. If `false`, the provided
     `acl` will be used without modification.
     */
    public static func setupDefaultPublicACL(read:Bool, write:Bool, withAccessForCurrentUser currentUserAccess:Bool = true) {
        let defaultACL = PFACL()
        defaultACL.getPublicReadAccess = read
        defaultACL.getPublicWriteAccess = write
        PFACL.setDefault(defaultACL, withAccessForCurrentUser: currentUserAccess)
    }

    /// A **synchronous** API to call a cloud function.
    ///
    /// - Parameter function: The name of the function.
    /// - Parameter params: The parameters to send to the function.
    /// - Returns: The result of the function.
    /// - Throws: The server error that was returned.
    @discardableResult
    public static func call(function: String, with params: Params? = nil) throws -> Any {
        return try PFCloud.callFunction(function, withParameters: params)
    }

    /// An **asynnchronous** API to call a cloud function.
    ///
    /// - Parameter function: The name of the function.
    /// - Parameter params: The parameters to send to the function.
    /// - Parameter block: The block to execute when the function call finished. It should have the following argument signature: `(result,error)`.
    public static func callInBackground(function: String, with params: Params? = nil, block: FunctionResultBlock?) {
        PFCloud.callFunction(inBackground: function, withParameters: params, block: block)
    }

}

extension Notification.Name {

    /// Notification sent when the global config has been updated from the server. You can update the configuration data
    /// by calling `Config.updateConfiguration` method.
    public static let HyperdriveConfigUpdatedNotification = NSNotification.Name("HyperdriveConfigUpdatedNotification")

    /**
     Notification sent when the server responds with a session error. This could mean the current logged in user token
     is invalid or has been revoked.
     - attention: When this is received, the application should immediately logout the user as they will not be ble to access
     any non-public readable data from the server.
    */
    public static let HyperdriveSessionErrorNotification = Notification.Name(rawValue: "HyperdriveSessionErrorNotification")
}

open class Config {

    open class func key(_ key:String) -> AnyObject? {
        return PFConfig.current().object(forKey: key) as AnyObject?
    }

}

// MARK: Upgrade Extension

public struct LaunchState {
    public enum Mode {
        case restart, install, upgrade
    }
    public var mode = Mode.restart
    public let build:Int
}


extension Hyperdrive {

    public static var currentBuildVersion:Int {
        get {
            return UserDefaults.standard.object(forKey: "AppBuildVersionKey") as? Int ?? 0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "AppBuildVersionKey")
        }
    }

    /// Determines whether this app is an install, upgrade or regular lanuch (restart). After the block
    /// returns, if the result is true, the internal build version will be updated. Use this method to determine
    /// the state of the launch and do any attribution tracking or upgrade changes that need to be made.
    public static func updateLaunchState(completion:(LaunchState)->(Bool)) {
        let previousBuildVersion = Self.currentBuildVersion
        //in case we used the previous value format
        let buildVersion = Bundle.currentBuildVersion
        var result = LaunchState(mode: .restart, build: buildVersion)

        if previousBuildVersion == 0 {
            result.mode = .install
        } else if previousBuildVersion < buildVersion {
            result.mode = .upgrade
        }
        // If true we update the build version.
        if completion(result) {
            currentBuildVersion = buildVersion
        }
    }
}

extension Config {
    /// Returns the `minimumiOSBuildVersion` config value. Defaults to 0
    open class var minimumBuildVersion:Int {
        return key("minimumiOSBuildVersion") as? Int ?? 0
    }

    /// Returns the `maintenance` boolean config value. Defaults to false.
    open class var maintenance:Bool {
        return key("maintenance") as? Bool ?? false
    }

    /// Returns true if the `minimumBuildVersion` remote config value is greater than
    /// the current build version in the bundle (`CFBundleVersion`).
    open class var needsUpgrade:Bool {
        return Config.minimumBuildVersion > Bundle.currentBuildVersion
    }


}

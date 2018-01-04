//
//  Upgrade+Ext.swift
//  Bolts
//
//  Created by Anthony Persaud on 1/4/18.
//  Copyright © 2018 Modernistik LLC. All rights reserved.
//

public typealias LaunchStateResult = (LaunchState) -> Void


/// Represents the different launch states of the app across the lifecycle usage of a user.
/// A user can freshly install a new app, receive an app ugprades or just use the app after a while..
///
/// - install: A fresh install of the app.
/// - upgrade: Indication that this launch of the app is newer than the previous launch.
/// - restart: A normal usage of the app.
public enum LaunchState {
    /// This is indicates that this launch is a fresh new install of the app (first run).
    case install
    /// This indicates the app has restarted, but nothing has changed in terms of build version.
    case restart
    /// Indicates that this launch of the app is newer than the previous launch.
    case upgrade
}



extension UIApplicationDelegate where Self: UIResponder {
    
    /**
    Method to calls to update the launch state. The completion
    handler will provide information on whether it is an install,
    upgrade or restart. See `LaunchState`.
     ## Example
     An example of using this method in your AppDelegate. The
     ````
     updateLaunchState { (launch) in
       switch launch {
       case .install:
          // a fresh install
       case .upgrade:
          // perform upgrade
       case .restart:
          // a general restart of the app.
       }
     }
     
     ````
    - parameter completion: The result block with the determined launch state.
    */
    public func updateLaunchState(completion:LaunchStateResult) {
        UIApplication.updateLaunchState(completion: completion)
    }
        
}
extension UIApplication {
    
    /**
     Method to calls to update the launch state. The completion
     handler will provide information on whether it is an install,
     upgrade or restart. See `LaunchState`.
     ## Example
     An example of using this method in your AppDelegate. The
     ````
     updateLaunchState { (launch) in
       switch launch {
       case .install:
         // a fresh install
       case .upgrade:
         // perform upgrade
       case .restart:
         // a general restart of the app.
       }
     }
     
     ````
     - parameter completion: The result block with the determined launch state.
     */
    public func updateLaunchState(completion:LaunchStateResult) {
        UIApplication.updateLaunchState(completion: completion)
    }
    
    /**
    This method provides a hook in handling installs, upgrades and resumes of the app by storing and comparing
    the previous build version that ran with the current one. After the block returns, if the
    result is true, the internal build version will be updated. Use this method to determine
    the state of the launch and do any attribution tracking or upgrade changes that need to be made.
    ## Example
    An example of using this method in your AppDelegate. The
    ````
     updateLaunchState { (launch) -> (Bool) in
     
        switch launch {
        case .install:
            // a fresh install
        case .upgrade:
            // perform upgrade
        case .restart:
            // a general restart of the app.
        }
        return true
     }
     
    ````
    - important: This method should **only** be called once in your AppDelegate.
   
    - parameter completion: The result block that will with signature `(state) -> Bool`.
 */
    public static func updateLaunchState(completion:LaunchStateResult) {
        // A special value that stores the last build version. This is used to track when the app
        // has been installed and upgraded as the this value should be lower than the current build version.
        let AppLastLaunchBuildVersionKey = "MKAppLastLaunchBuildVersionKey"
        
        // Get the last stored build version.
        let previousBuildVersion = UserDefaults.standard.object(forKey: AppLastLaunchBuildVersionKey) as? Int ?? 0
        
        // Get the current build version. This could be newer than the last time the app launched.
        let buildVersion = Bundle.currentBuildVersion
        let result:LaunchState
        
        if previousBuildVersion == 0 {
            result = .install
        } else if previousBuildVersion < buildVersion {
            result = .upgrade
        } else {
            result = .restart
        }
        completion(result)
        UserDefaults.standard.set(buildVersion, forKey: AppLastLaunchBuildVersionKey)
    }
    
}

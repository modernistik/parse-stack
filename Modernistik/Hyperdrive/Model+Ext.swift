//
//  Model+Ext.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/4/18.
//

import Parse


extension PFACL {
    
    public func setAccessFor(user:PFUser?, read:Bool = true, write:Bool = false) {
        if let user = user {
            setReadAccess(write, for: user)
            setWriteAccess(read, for: user)
        }
    }
    
    public func setFullAccessFor(user:PFUser?) {
        setAccessFor(user: user, read: true, write: true)
    }
    
}


extension PFUser {
    
    /// Alias for `User.current()?.objectId`
    public class var currentUserId:String? {
        return current()?.objectId
    }
    
    /// Whether the current user is logged in.
    open class var isAvailable:Bool {
        return current() != nil
    }
    
    /// Whether the current user is anonymous (unregistered)
    open class var isAnonymous:Bool {
        guard let user = current() else { return false }
        return PFAnonymousUtils.isLinked(with: user)
    }
    
    /// Whether the current user is logged in and is not anonymous.
    open class var isRegistered:Bool {
        return isAvailable && !isAnonymous
    }
    
    /// Returns the current user only if they are logged in and not in an anonymous state.
    ///
    /// - Returns: The user if they are registered and logged in.
    open static func registeredUser() -> Self? {
        let user = current()
        return ( user == nil || PFAnonymousUtils.isLinked(with: user) ) ? nil : user
    }
    
}

public func ==(x:PFUser, y:PFUser) -> Bool {
    return x.objectId == y.objectId && x.objectId != nil && y.objectId != nil
}

extension PFInstallation {
    
    open class func registerPush(deviceToken:Data, block:PFBooleanResultBlock? = nil) {
        guard let current = current() else { return }
        current.setDeviceTokenFrom(deviceToken)
        saveInstallation(block: block)
    }
    /// Saves (eventually) the current installation in background.
    open class func saveInstallation(block:PFBooleanResultBlock? = nil) {
        guard let current = current() else { return }
        current.saveEventually(block)
    }
}

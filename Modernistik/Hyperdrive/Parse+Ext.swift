//
//  Modernistik
//  Copyright © 2016 Modernistik LLC. All rights reserved.
//

import Foundation
import Parse
import TimeZoneLocate

extension PFObject {

    /// Converts the object into a pointer dictionary.
    public var pointer: [String:Any?]? {
        assert(objectId != nil, "Tried to encode a pointer with no objectId.")
        guard let o = objectId else { return nil }
        return ["__type": "Pointer", "className": parseClassName, "objectId": o]
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? PFObject else { return false }
        return self == object
    }

    /// Returns `true` if this object does not have an objectId.
    public var isNew:Bool {
        return objectId == nil
    }
}


extension PFSubclassing where Self: PFObject {

    /// Initialize an instance of the Parse subclass with using objectId, returning nil
    /// if the value passed to id is not valid.
    /// ## Example
    ///     let pointer = User(id: "ob123ZYX")
    /// - parameter id: The objectId of the object you want to represent.
    public init?(id:Any?) {
        guard let id = id as? String else { return nil }
        self.init(withoutDataWithClassName: String(describing: Self.self), objectId: id)
    }

}

/// Compares two Parse objects by checking their objectId field and their class type.
///
/// - Parameters:
///   - x: A Parse object..
///   - y: A Parse object
/// - Returns: `true` if both objects represent the same record.
public func ==(x:PFObject, y:PFObject) -> Bool {
    return x.objectId == y.objectId && x.objectId != nil && type(of: x) == type(of: y)
}

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


extension CLLocation {

    /// Return a PFGeoPoint representing this CLLocation
    public var geoPoint:PFGeoPoint? {
        return PFGeoPoint(location: self)
    }

}


extension CLLocationCoordinate2D {

    /// Returns a geoPoint object from this location.
    public var geoPoint:PFGeoPoint {
        return PFGeoPoint(latitude: latitude, longitude: longitude)
    }
}

extension PFGeoPoint {

    public class var zero: PFGeoPoint {
        return PFGeoPoint(latitude: 0, longitude: 0)
    }
    /// A convenience setter and getter to convert between PFGeoPoints and CLLocation objects
    public var location:CLLocation {
        get {
            return CLLocation(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue.coordinate.latitude
            longitude = newValue.coordinate.longitude
        }
    }

    //estimate within 0.69 miles
    public var estimated:PFGeoPoint {
        return rounded(digits: 1)
    }

    public func rounded(digits:Double = 1) -> PFGeoPoint {

        let multiplier = pow(10, digits)
        let lat = round( multiplier * latitude ) / multiplier //weird that it comes back as .00000000001
        let lng = round( multiplier * longitude ) / multiplier
        return PFGeoPoint(latitude: lat, longitude: lng)
    }

}

public func ==(l:PFGeoPoint, r:PFGeoPoint) -> Bool {
    return l.latitude == r.latitude && l.longitude == r.longitude
}

extension Error {

    /// Returns `true` if the error is a Parse cache miss (120) error.
    /// See `PFErrorCode.errorCacheMiss`
    public var isCacheMiss:Bool {
        return code == PFErrorCode.errorCacheMiss.rawValue
    }

    /**
    Returns an error only if we consider this being a critical error. In general,
    all errors are critical except for two Parse errors: cache and sesion errors.

    It is usually expected that you handle errors in your queries and api calls.
    We recomned using the following pattern:
    ````
    if error == nil {
     // success
    } else if let error = error?.validError {
     // handle a non-cache or non-session error
    }
    ````
    ## Cache Errors
    Cache error are light errors but may not affect the continuation of the request. For example,
    if you perform a query with a cache policy of `.cacheThenNetwork` and there are no cached results
    for the query, you will receive a `.errorCacheMiss` (120) error, however, the query will continue
    going to the network to get server results.
    ## Session Errors
    These errors require special handling. In this case, this method will return nil in order to prevent your
    the error handling from executing. However, a `HyperdriveSessionErrorNotification` will be posted to the
    default notification center in order for you to handle the session error and log out the user of the application.
     This design pattern helps you from having to verify session errors in every query or API callback result block.
     */
    public var validError:Error? {
        if isCacheMiss { return nil }
        if isSessionError {
            NotificationCenter.default.post(name: .HyperdriveSessionErrorNotification, object: self, userInfo: nil)
            return nil
        }
        return self
    }

    /// Returns `true` if this error was due to an object not found or
    /// whether a query or object refresh produced no results. This could happen
    /// if the object doesn't exist in the system, or the current user is not allowed
    /// to view the object due to ACLs.
    /// See `PFErrorCode.errorObjectNotFound`
    public var isObjectNotFound:Bool {
        return code == PFErrorCode.errorObjectNotFound.rawValue && domain == "Parse"
    }

    /// Returns `true` if this is a connection failure when connected to Parse server.
    /// See `PFErrorCode.errorConnectionFailed`
    public var isOffline:Bool {
        return code == PFErrorCode.errorConnectionFailed.rawValue && domain == "Parse"
    }

    /// Cloud code script or hook had an error (Ex. before save hook fails)
    /// See `PFErrorCode.scriptError`
    public var isScriptError:Bool {
        return code == PFErrorCode.scriptError.rawValue && domain == "Parse"
    }

    /// Returns `true` if this is a Parse validation error.
    /// See `PFErrorCode.validationError`
    public var isValidationError:Bool {
        return code == PFErrorCode.validationError.rawValue && domain == "Parse"
    }

    /**
     Whether the error that occurs wasn't critical, and the original request can be retried.
     This may happen for a number of reasons, mostly due to network congestion or throttling.
     
     ## Rules
        * Errors with codes 3840 and 100, which are `bad json` Parse errors are retriable.
        * Parse errors `errorInternalServer`, `errorConnectionFailed`, `errorTimeout`,
        `errorRequestLimitExceeded`, and `errorExceededQuota` are retriable
        * Anything else is should not cause the app to retry a request to the server.
    */
    public var isRetriable:Bool {
        if code == 3840 || code == 100 {
            // bad json - usually heroku app misconfigured, which returns HTML instead of Parse JSON
            return true
        }
        guard domain == "Parse", let errorCode = PFErrorCode(rawValue: code) else { return false }

        switch errorCode {
        case .errorInternalServer, .errorConnectionFailed, .errorTimeout, .errorRequestLimitExceeded, .errorExceededQuota:
            return true
        default:
            return false
        }
    }

    /// Returns true if this is a Parse invalid session token error.
    /// A session error occurs when the session token
    /// for the user has expired or has been revoked in Parse.
    /// When this happens, the current user should be logged out of the app.
    public var isSessionError:Bool {
        return code == PFErrorCode.errorInvalidSessionToken.rawValue || code == PFErrorCode.errorUserCannotBeAlteredWithoutSession.rawValue
    }

    /// Return the error code.
    public var code:Int {
        return (self as NSError).code
    }
    
    /// Return the domain string for the error.
    public var domain:String {
        return (self as NSError).domain
    }
}


public protocol TimeZoneAccessible: class {
    var location:PFGeoPoint? { get }

}

extension PFGeoPoint {
    /// Gets the timeZone at this particular location
    public var timeZone:TimeZone {
        return location.timeZone
    }
}

extension TimeZoneAccessible where Self: PFObject {
    public var timeZone:TimeZone {
        get {
            //use the genereated zone if available
            if let timeZoneName = self["timeZone"] as? String, let tz = TimeZone(identifier: timeZoneName) {
                return tz
            } else if let tz = location?.timeZone {
                self["timeZone"] = tz.identifier
                updateTimeZone() // kick off async to get more accurate time zone info
                return tz
            }
            return TimeZone.current
        }
        set {
            self["timeZone"] = newValue.identifier
        }
    }
    /// Updates the timeZone field with an accruate time zone by reverse geocoding the location field.
    public func updateTimeZone() {
        let coder = CLGeocoder()
        guard let loc = location?.location else { return }

        coder.reverseGeocodeLocation(loc) { (placemarks, error) in
            guard let tz = placemarks?.last?.timeZone else { return }
            self["timeZone"] = tz.identifier
        }
    }
}


extension Sequence where Iterator.Element : PFObject {
    
    /// Transforms a list of Parse Objects into a list of
    /// their corresponding objectIds. This method will handle the case
    /// where some objects may not have objectIds.
    public var objectIds:[String] {
        return flatMap { (obj) -> String? in
            obj.objectId
        }
    }
}

//
//  Modernistik
//  Copyright © 2016 Modernistik LLC. All rights reserved.
//

import Foundation
import Parse
import TimeZoneLocate

extension PFObject {

    public var pointer: [String:Any?]? {
        assert(objectId != nil, "Tried to encode a pointer with no objectId.")
        guard let o = objectId else { return nil }
        return ["__type": "Pointer", "className": parseClassName, "objectId": o]
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? PFObject else { return false }
        return self == object
    }

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

    open class var currentUserId:String? {
        return current()?.objectId
    }

    open class var isAvailable:Bool {
        return current() != nil
    }
    open class var isAnonymous:Bool {
        guard let user = current() else { return false }
        return PFAnonymousUtils.isLinked(with: user)
    }

    open class var isRegistered:Bool {
        return isAvailable && !isAnonymous
    }
    open class func registeredUser() -> Self? {
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

    public var isCacheMiss:Bool {
        return code == PFErrorCode.errorCacheMiss.rawValue
    }

    public var validError:Error? {
        if isCacheMiss { return nil }
        if isSessionError {
            NotificationCenter.default.post(name: .HyperdriveSessionErrorNotification, object: self, userInfo: nil)
            return nil
        }
        return self
    }

    public var isObjectNotFound:Bool {
        return code == PFErrorCode.errorObjectNotFound.rawValue && domain == "Parse"
    }

    public var isOffline:Bool {
        return code == PFErrorCode.errorConnectionFailed.rawValue && domain == "Parse"
    }

    /// Cloud code script or hook had an error (Ex. before save hook fails)
    public var isScriptError:Bool {
        return code == PFErrorCode.scriptError.rawValue && domain == "Parse"
    }

    public var isValidationError:Bool {
        return code == PFErrorCode.validationError.rawValue && domain == "Parse"
    }

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

    public var isSessionError:Bool {
        return code == PFErrorCode.errorInvalidSessionToken.rawValue || code == PFErrorCode.errorUserCannotBeAlteredWithoutSession.rawValue
    }

    public var code:Int {
        return (self as NSError).code
    }
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
    public var objectIds:[String] {
        return flatMap { (obj) -> String? in
            obj.objectId
        }
    }
}

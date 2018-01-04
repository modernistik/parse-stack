//
//  GeoPoint+Ext.swift
//  Bolts
//
//  Created by Anthony Persaud on 1/4/18.
//

import Parse

extension CLLocationCoordinate2D {
    
    /// Returns a geoPoint object from this location.
    public var geoPoint:PFGeoPoint {
        return PFGeoPoint(latitude: latitude, longitude: longitude)
    }
}

extension CLLocation {
    
    /// Return a PFGeoPoint representing this CLLocation
    public var geoPoint:PFGeoPoint? {
        return PFGeoPoint(location: self)
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


extension PFGeoPoint {
    /// Gets the timeZone at this particular location
    public var timeZone:TimeZone {
        return location.timeZone
    }
}

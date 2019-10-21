//
//  MapKit+Ext.swift
//  Modernistik
//
//  Created by Anthony Persaud on 3/13/16.
//

import Foundation
import MapKit

extension MKMapView {
    public func showcaseMap(address: String) {
        CLGeocoder().geocodeAddressString(address) { (placemarks, error) -> Void in
            if error == nil, let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate {
                self.showcaseMapAtCoordinate(coordinate: coordinate)
            }
        }
    }

    public func showcaseMapAtCoordinate(coordinate: CLLocationCoordinate2D, withOffsetDistance offsetDistance: CLLocationDistance = 0.005, fromAltitude altitude: CLLocationDistance = 175, animated: Bool = false) {
        let eyeCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude + offsetDistance, longitude: coordinate.longitude + offsetDistance)
        let camera = MKMapCamera(lookingAtCenter: coordinate, fromEyeCoordinate: eyeCoordinate, eyeAltitude: altitude)
        setCamera(camera, animated: animated)
    }

    public func animateFlyover() {
        if let camera = self.camera.copy() as? MKMapCamera {
            UIView.animate(withDuration: 300, delay: 0,
                           options: [.curveEaseOut], animations: { () -> Void in
                               camera.heading += 60
                               self.camera = camera
            }, completion: nil)
        }
    }
}


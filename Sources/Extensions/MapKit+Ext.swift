//
//  MapKit+Ext.swift
//  Modernistik
//
//  Created by Anthony Persaud on 3/13/16.
//

import CoreLocation
import Foundation
import MapKit

extension MKMapView {
    /// Present the provided location in the map view area from a camera angle that is offset from there. The address argument is
    /// geocoded in order to obtain the actual coordinates for the map camera.
    /// - Parameter address: The address to geocode and present in the MKMapView
    /// - Parameter offsetDistance: The distance to offset the camera from the `coordinate`. (Default: 0.005)
    /// - Parameter altitude: The height of the camera, which affects the visibility angle. (Default: 175)
    /// - Parameter animated: Whether we should animate the camera to present the provided location.
    public func showcaseMap(address: String,
                            withOffsetDistance offsetDistance: CLLocationDistance = 0.005,
                            fromAltitude altitude: CLLocationDistance = 175, animated: Bool = false) {
        CLGeocoder().geocodeAddressString(address) { (placemarks, error) -> Void in
            if error == nil, let placemark = placemarks?.first, let coordinate = placemark.location?.coordinate {
                self.showcaseMap(at: coordinate, withOffsetDistance: offsetDistance, fromAltitude: altitude, animated: animated)
            }
        }
    }

    /// Present the provided location in the map view area from a camera angle that is offset from there.
    /// - Parameter coordinate: The location to present in the map.
    /// - Parameter offsetDistance: The distance to offset the camera from the `coordinate`. (Default: 0.005)
    /// - Parameter altitude: The height of the camera, which affects the visibility angle. (Default: 175)
    /// - Parameter animated: Whether we should animate the camera to present the provided location.
    public func showcaseMap(at coordinate: CLLocationCoordinate2D,
                            withOffsetDistance offsetDistance: CLLocationDistance = 0.005,
                            fromAltitude altitude: CLLocationDistance = 175, animated: Bool = false) {
        let eyeCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude + offsetDistance, longitude: coordinate.longitude + offsetDistance)
        let camera = MKMapCamera(lookingAtCenter: coordinate, fromEyeCoordinate: eyeCoordinate, eyeAltitude: altitude)
        setCamera(camera, animated: animated)
    }

    /// Animates the current map camera around the current visible location.
    /// - note: You must have called `showcaseMap` to setup the camera before animating flyover.
    /// - Parameter duration: The duration of the animation
    /// - Parameter headingDistance: The amount of arc-distance to travel. 180 would be considered half way around.
    public func animateFlyover(duration: TimeInterval = 120, headingDistance: CLLocationDirection = 90) {
        if let camera = self.camera.copy() as? MKMapCamera {
            UIView.animate(withDuration: duration, delay: 0,
                           options: [.curveEaseOut], animations: { () -> Void in
                               camera.heading += headingDistance
                               self.camera = camera
            }, completion: nil)
        }
    }
}

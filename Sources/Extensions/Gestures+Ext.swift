//
//  Gestures+Additions.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

extension UIPanGestureRecognizer {
    /// The most-traveled cardinal direction for this pan gesture (up, down, left, right)
    public var primaryDirection: UISwipeGestureRecognizer.Direction {
        let translationX = translation(in: view).x
        let translationY = translation(in: view).y
        // Note: could add a margin of certainty as parameter, so one direction has to be overwhelmingly obvious or else it is nil
        if abs(translationX) > abs(translationY) {
            return translationX > 0 ? .right : .left
        }
        return translationY > 0 ? .down : .up
    }

    /// Returns true if pan speed is fast enough to act as a "swipe" action. `threshold` defaults to **300**.
    public func exceedsPanningVelocity(threshold: CGFloat = 300) -> Bool {
        // X and Y velocity is always the same, as far as I can tell - Henry
        abs(velocity(in: view).x) > threshold
    }
}

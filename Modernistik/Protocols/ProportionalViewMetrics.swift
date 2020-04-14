//
//  ProportionalViewMetrics.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import CoreGraphics
import Foundation
import UIKit

/** Provides a standard interface to get recommended proportional heights based on
 different sized devices or viewports. The idea behind this pattern is in defining an aspect
 ratio that this view prefers. By adopting this protocol and setting the `aspectRatio`, several
 extensions will make it easier to determine correct sizes utilizing this value.
 # Example

 ```
 // Adopt the protocol
 class MyView : ModernView, ProportionalViewMetrics {
    static var aspectRatio:CGFloat = 1920/1080
 }

 // Using the aspect ratio, we can calculate proper sizes
 MyView.recommendedHeight(forWidth: 640) //-> 360
 ```
 */
public protocol ProportionalViewMetrics {
    /// The recommended height for this view. The default implementation is the width of
    /// the UIScreen.mainScreen() divided by the aspectRatio.
    static var recommendedHeight: CGFloat { get }

    /**
      Returns the height based on the aspectRatio for a given width. By default, this is
      is calculated by width/aspectRatio. The default implementation
      returns the `recommendedHeight` value.
      # Example

      ```
      // Assume subclass
      class MyView : ModernView, ProportionalViewMetrics {
         static var aspectRatio:CGFloat = 1920/1080
      }

      // Using the aspect ratio, we can calculate proper sizes
      MyView.recommendedHeight(forWidth: 640) //-> 360
      ```
     - parameter forWidth: the width to use when calculating the height.
     - returns: The recommended height based on input width.
     */
    static func recommendedHeight(forWidth: CGFloat) -> CGFloat

    /// The ratio between width and height of the view. To calculate the height
    /// we would divide the width by the aspectRatio (width/height).
    static var aspectRatio: CGFloat { get }
    /// Returns 1/aspectRatio (height/width).
    static var inverseAspectRatio: CGFloat { get }
}

extension ProportionalViewMetrics {
    /// The ratio between width and height of the view. To calculate the height
    /// we would divide the width by the aspectRatio (width/height).
    public static var aspectRatio: CGFloat { 1 }
    /// Returns `1/aspectRatio` (height/width).
    public static var inverseAspectRatio: CGFloat { 1 / aspectRatio }
    /// The ratio between width and height of the view. To calculate the height
    /// we would divide the width by the aspectRatio (width/height).
    public static var recommendedHeight: CGFloat {
        UIScreen.main.bounds.width / aspectRatio
    }

    /// The recommended height for the given with, with respect to the current
    /// aspectRatio (width/height).
    /// - parameter width: The width to use to calculate the height.
    public static func recommendedHeight(forWidth width: CGFloat) -> CGFloat {
        width / aspectRatio
    }

    /// Returns a size with a recommended height based on the supplied width.
    /// Shorthand for:
    /// ```
    /// CGSize(width: width, height: recommendedHeight(forWidth: width))
    /// ```
    /// - parameter width: The width to use to calculate the height.
    public static func recommendedSize(forWidth width: CGFloat) -> CGSize {
        CGSize(width: width, height: recommendedHeight(forWidth: width))
    }
}

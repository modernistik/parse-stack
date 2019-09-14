//
//  Modernistik
//  Copyright © Modernistik LLC. All rights reserved.
//
import CoreGraphics
import UIKit.UIColor

extension CGColor {
    /// Converts a CGColor to a UIColor instance.
    public var color: UIColor {
        return UIColor(cgColor: self)
    }
}

extension CGFloat {
    /// Same as Double.pi / 2 or M_PI_2
    public static var pi_2: CGFloat {
        return .pi / 2
    }

    /// Round to a specific number of decimal places.
    /// ```
    ///    1.23556789.roundTo(3) // 1.236
    /// ```
    /// - parameter decimalPlaces: The number decimal places to keep.
    public func roundTo(_ decimalPlaces: Int) -> CGFloat {
        return CGFloat(Double(self).roundTo(decimalPlaces))
    }
}

extension CGPoint {
    /// Returns a copy with the x value changed.
    ///
    /// - parameter x: The new x-coordinate valud
    /// - returns: A CGPoint with the x coordinate modified
    public func with(x: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: y)
    }

    /// Returns a copy with the y value changed.
    ///
    /// - parameter y: The new y-coordinate valud
    /// - returns: A CGPoint with the y coordinate modified
    public func with(y: CGFloat) -> CGPoint {
        return CGPoint(x: x, y: y)
    }

    /// Returns the distance to another point.
    ///
    /// - parameter point: The target point to use for calculation.
    /// - returns: The distance to target point from current one.
    public func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
}

extension CGSize {
    /// Returns a square size based on the provided size.
    ///
    ///     let size:CGSize = .square(40)
    ///
    /// - parameter size: the dimension of each side (width and height)
    /// - returns: A new CGSize with equal width and height
    public static func square(_ size: CGFloat) -> CGSize {
        return CGSize(width: size, height: size)
    }

    /// Returns a square size based on the provided size.
    ///
    ///     let size = CGSize(square: 30)
    ///
    ///     // alias
    ///     let size:CGSize = .square(30)
    ///
    /// - parameter size: The value for width and height
    public init(square size: CGFloat) {
        self.init(width: size, height: size)
    }

    /// Returns a CGRect with size equal to this CGSize at origin point.
    /// ```
    ///   CGSize(square: 80).rect
    ///   // CGRect x,y = {0,0} width,height = {80,80}
    /// ```
    public var rect: CGRect {
        return CGRect(width: width, height: height)
    }

    /// Returns a new size that proportionally fits within the provided size.
    /// - note: The width and height values must be greater than 0.
    /// - parameter maxSize: The maximum size to bound the target size.
    public func aspectFit(to maxSize: CGSize) -> CGSize {
        guard width > 0, height > 0 else { return .zero }
        let widthRatio = maxSize.width / width
        let heightRatio = maxSize.height / height
        return widthRatio > heightRatio ?
            CGSize(width: width * heightRatio, height: height * heightRatio) :
            CGSize(width: width * widthRatio, height: height * widthRatio)
    }
}

extension CGRect {
    /// Returns a new rect by swapping width and height value.
    ///
    ///     let rect:CGRect = CGRect(width: 100, height: 50).pivoted
    ///
    ///     rect.size.height == 100 // true
    ///     rect.size.width == 50 // true
    /// - returns: A new rect rotated 90 degrees from anchor point.
    public var pivoted: CGRect {
        return with(width: height, height: width)
    }

    /// Returns true if `width > height`
    public var isHorizontal: Bool {
        return width >= height
    }

    /// Returns true if `width < height`
    public var isVertical: Bool {
        return width <= height
    }

    /// Returns true if `width == height`
    public var isSquare: Bool {
        return width == height
    }

    /// Returns a square rect based on the provided size setting the coordinates to origin.
    ///
    ///     let rect:CGRect = .square(40)
    /// - parameter size: The dimensions for width and height.
    /// - returns: A new rect with origin coordinates and equal sides.
    public static func square(_ size: CGFloat) -> CGRect {
        return CGRect(x: 0, y: 0, width: size, height: size)
    }

    /// Returns a CGRect with square sides with origin coordinates.
    ///
    /// - parameter size: The value to set both width and height
    public init(square size: CGFloat) {
        self.init(x: 0, y: 0, width: size, height: size)
    }

    /// Create a new CGRect with origin coordinates, but with the provided width and height.
    ///
    /// - parameter width: The width for the rect.
    /// - parameter height: The height for the rect.
    public init(width: CGFloat, height: CGFloat) {
        self.init(x: 0, y: 0, width: width, height: height)
    }

    /// Create an inset square CGRect that is centered in the parent with the given size. This
    /// is useful when you want to create a square inside a non-uniform rectangle, but maintain centering.
    ///
    /// - parameter size: The amount to reduce from each side.
    /// - returns: A CGRect representing the new inset square.
    public func squareInset(size: CGFloat) -> CGRect {
        let c = center
        let offset: CGFloat = size / 2.0
        let _x = c.x - offset
        let _y = c.y - offset
        return CGRect(x: _x, y: _y, width: size, height: size)
    }

    /// Create an inset square CGRect that is centered in the parent by reducing the shortest side by `delta`.
    ///
    /// - parameter delta: the amount to reduce (dx and dy)
    /// - Returns: The CGRect of the new inset square.
    public func squareInset(delta: CGFloat) -> CGRect {
        let f = insetBy(dx: delta, dy: delta)
        return f.squareInset(size: f.shortest - delta)
    }

    /// Returns a rect for an inscribed square using the rect's shortest side.
    /// Alias for `squareInset(size: shortest)`.
    public var square: CGRect {
        return squareInset(size: shortest)
    }

    /**
     Returns the rect of an inscribed square contained in the circle that circumscribes the source rect.
     The diagonal of a square inscribed in a circle is sqrt(2) times the length of a side.

     From a bounds perspective, the shortest side will be used as the diameter of the circumscribing circle,
     in order to calculate the inner inscribed square of that circle. The ratio of the outer square side
     to the innser square is sqrt(2) for each side.

      ## Disucssion ##
      This is useful if you have some type of icon or view that is circular, and you need to calculate
      the largest frame (CGRect) that can comfortably fit inside the circular parent view, but centered around
      the parent's position. A good example would be the circular badge display, where the parent view is circular,
      but the numeric badge (UILabel) is centered around that circle.
     */
    public var squareInscribedInCircle: CGRect {
        // get the inscribed square given the inscribed circle
        // M_SQRT1_2 == 1/sqrt(2)
        let ratio = CGFloat(0.5.squareRoot())
        // the ratio of the outer square side to the innser square is sqrt(2).
        // outer_side = inner_side * sqrt(2)
        // so new square should be inset by:
        //    outer_side * ( 1 / sqrt(2) ) -> outer_sde * (M_SQRT1_2)
        // to inset, we need the delta between the outer edge and inner edge and divide by two (for each side)
        let insetAmount: CGFloat = shortest * (1 - ratio) / 2.0 // could optimize to sub (1 - ratio) => 0.292893.
        return insetBy(dx: insetAmount, dy: insetAmount)
    }

    /// returns half the value of the shortest side. Useful for when calculating corner radius
    public var half: CGFloat {
        return shortest / 2.0
    }

    /// Get the center point of this rect. Useful when needing to center two views together.
    public var center: CGPoint {
        return CGPoint(
            x: origin.x + width / 2.0,
            y: origin.y + height / 2.0
        )
    }

    /// Alias for origin.x.
    public var left: CGFloat {
        get { return minX }
        set { origin.x = newValue }
    }

    /**
     Alias access for `maxX`. However, it can also be modified to offset the
     rect based on where you want the right edge (maxX) to end up. Useful in repositioning views.

     ### Disucssion ###
     Assume you want to position a view's `origin.x`, so that the right edge ends up in
     a specific spot.

     ````
     frame = CGRect(x: 10, y: 20, width: 50, height: 50)
     frame // {x 10 y 20 w 50 h 50}
     frame.right // 60
     ````
     The `frame.right` value has an x-coordinate of 60 since the view's `origin.x` starts
     at 10 and extends for 50 more points. If you want to change
      the right edge (`maxX`) so that ends up being 40:
     ````
     frame.right = 40
     frame // {x -10 y 20 w 50 h 50}
     ````
     */
    public var right: CGFloat {
        get { return maxX }
        set { origin.x = newValue - width }
    }

    /// Alias for `minY`, however it can be set to modify the `origin.y`.
    public var top: CGFloat {
        get { return minY }
        set { origin.y = newValue }
    }

    /**
     Alias access for `maxY`. However, it can also be modified to offset the
     rect based on where you want the bottom edge (maxY) to end up. Useful in repositioning views.

     ### Disucssion ###
     Assume you want to position a view's `origin.y`, so that the bottom edge ends up in
     a specific spot.

     ````
     frame = CGRect(x: 10, y: 20, width: 50, height: 50)
     frame // {x 10 y 20 w 50 h 50}
     frame.bottom // 70
     ````
     The `frame.bottom` value has a y-coordinate of 70 since the view's `origin.y` starts
     at y = 20 and extends for 50 more points. If you want to change
     the bottom edge (`maxY`) so that ends up being 40:

     ````
     frame.bottom = 40
     frame // {x 10 y -10 w 50 h 50}
     ````
     */
    public var bottom: CGFloat {
        get { return maxY }
        set { origin.y = newValue - height }
    }

    /// Returns a new CGRect with the modified width
    ///
    /// - parameter width: The new width value.
    /// - returns: a new CGRect with the modified width.
    public func with(width: CGFloat, height: CGFloat? = nil) -> CGRect {
        return CGRect(x: origin.x, y: origin.y, width: width, height: height ?? size.height)
    }

    /// Returns a new CGRect with the modified height
    ///
    /// - parameter height: The new height value.
    /// - returns: a new CGRect with the modified height.
    public func with(height: CGFloat) -> CGRect {
        return CGRect(x: origin.x, y: origin.y, width: size.width, height: height)
    }

    /// Returns a new CGRect with only the origin (both x and y) modified.
    /// All other values will remain the same.
    ///
    /// - parameter x: The new x coordinate.
    /// - parameter y: The new y coordinate.
    /// - returns: a new CGRect with the modified coordinates
    public func with(x: CGFloat, y: CGFloat? = nil) -> CGRect {
        return CGRect(x: x, y: y ?? origin.y, width: width, height: size.height)
    }

    /// Returns a new CGRect with only the y-origin modified.
    /// - parameter y: The new y coordinate.
    /// - returns: a new CGRect with the modified coordinates
    public func with(y: CGFloat) -> CGRect {
        return with(x: origin.x, y: y)
    }

    /// Returns a square CGRect with width and height set to same value.
    ///
    /// - parameter square: The new value for both width and height.
    /// - returns: a new CGRect with the modified dimensions
    public func resize(square: CGFloat) -> CGRect {
        return with(width: square, height: square)
    }

    /// Returns the smallest value of either the width or height
    public var shortest: CGFloat {
        return min(width, height)
    }

    /// Returns the longest value of either the width or height
    public var longest: CGFloat {
        return max(width, height)
    }

    /// In place modification of width and height size attributes
    ///
    /// - parameter width: the new width
    /// - parameter height: the new height
    public mutating func resize(width: CGFloat, height: CGFloat) {
        size.width = width
        size.height = height
    }
}

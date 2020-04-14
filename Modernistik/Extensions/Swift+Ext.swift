//
//  Modernistik
//  Copyright © Modernistik LLC. All rights reserved.
//

import CoreGraphics
import Foundation
import UIKit

/// Alias for `[AnyHashable: Any]`
public typealias ObjectDictionary = [AnyHashable: Any?]

/// Alias for `[String: Any]`
public typealias StringDictionary = [String: Any?]

extension Sequence where Iterator.Element: RawRepresentable {
    /**
     Transform a list of enums of RawRepresentable type, into a list of their rawValues.

     ````
     // Int is RawRepresentable
     enum Colors: Int {
        case blue, red, yellow
     }

     let colors: [Colors] = [.blue, .yellow, .red]
     colors.rawValues # => [0,2,1]
     ````

     - returns: An array of rawValues based on enum RawRepresentable type.
     */
    public var rawValues: [Iterator.Element.RawValue] {
        map { $0.rawValue }
    }
}

extension Equatable {
    /// True if the target matches any of the ones provided in the list.
    /// ```
    /// // Example with enums
    /// enum Color {
    ///     case red, green, blue, yellow
    /// }
    ///
    /// let color = Color.red
    ///
    /// color.any(.green, .red) // true
    /// ```
    /// - important: If you only need to check
    /// against 1 item type, it is recommended using the `==` operator instead.
    /// - parameter items: A variable list of items to check against.
    public func any(of items: Self...) -> Bool {
        items.contains(self)
    }
}

extension Set {
    /// True if any of the items are inside the set.
    /// - parameter enums: A variable list of enums to check against.
    public func contains(any items: Element...) -> Bool {
        intersection(items).isEmpty == false
    }
}

/// Requires the implementor to support being initialized with an integer
public
protocol IntegerInitializable: ExpressibleByIntegerLiteral {
    /// Protocol that allows the implementor to initilize itself with an integer.
    init(_: Int)
}

postfix operator °
extension Int: IntegerInitializable {
    /// Turns the number (interpreted as an angle) into radians with the ° (degree) operator.
    ///  ````
    ///    let radians = 45.0° // => 0.785398163397448
    ///  ````
    /// - attention: To type the degree symbol, use (Option + Shift + 8)
    /// - parameter lhs: The integer to interpret as an angle.
    /// - returns: the number of radians
    public static postfix func ° (lhs: Int) -> CGFloat {
        CGFloat(lhs) * .pi / 180
    }
}

extension Double: IntegerInitializable {
    /// Turns the number (interpreted as an angle) into radians with the ° (degree) operator.
    ///  ````
    ///    let radians = 45.0° // => 0.785398163397448
    ///  ````
    /// - attention: To type the degree symbol, use (Option + Shift + 8)
    /// - parameter lhs: The integer to interpret as an angle.
    /// - returns: the number of radians
    public static postfix func ° (lhs: Double) -> CGFloat {
        CGFloat(lhs) * .pi / 180
    }
}

extension MutableCollection {
    /// Shuffles the contents of this collection. See also [Stack Overflow](https://stackoverflow.com/questions/24026510/how-do-i-shuffle-an-array-in-swift)
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }

        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            // Change `Int` in the next line to `IndexDistance` in < Swift 4.1
            let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    /// See also [Stack Overflow](https://stackoverflow.com/questions/24026510/how-do-i-shuffle-an-array-in-swift)
    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}

// MARK: Arrray extensions

extension Array {
    /// Randombly picks an item of the array
    public var sample: Element? {
        if count == 0 { return nil }
        let index = count.random
        return self[index]
    }

    /// Returns the last possible index of the Array
    public var lastIndex: Int {
        count - 1
    }

    /// Returns whether there are values in the array: (eg. `!isEmpty`).
    public var hasItems: Bool {
        !isEmpty
    }
}

// MARK: Array equatable extensions

extension Array where Element: Equatable {
    /// Removes the first instance of the element from the array
    ///
    /// - Parameter item: the item to remove if it exists
    public mutating func removeItem(_ item: Element) {
        if let itemIndex = firstIndex(of: item) {
            remove(at: itemIndex)
        }
    }
}

// MARK: Int extensions

extension Int {
    /// Return the radian value using the number as degrees.
    ///
    /// You can also use the degree symbol using (Option + Shift + 8).
    /// ```
    ///    35.degress == 35°
    /// ```
    public var degreesToRadians: CGFloat { CGFloat(self) * .pi / 180.0 }

    /// Returns the number of meters based on the miles provided
    public var milesToMeters: Int {
        1609 * self
    }

    /// Returns the number of bytes expressed using current value as MBs.
    public var MBs: Int { self * 1024 * 1024 }

    /// Returns a random integer less than the current value.
    ///
    ///     30.random // => 5
    ///     30.random // => 22
    public var random: Int {
        Int(arc4random_uniform(UInt32(self)))
    }

    /// Returns the current value unless it is outside one of the limit boundaries. In that case it returns that closest limit boundary.
    ///
    /// - parameter low: The lower limit boundary
    /// - parameter high: The higher limit boundary
    /// - returns: A value that is in range of the provided limits
    public func clamp(_ low: Int, _ high: Int) -> Int {
        (self > high) ? high : (self < low ? low : self)
    }

    /// Determines whether the current value is in the appropriate range
    ///
    /// - parameter low: The lower bound value
    /// - parameter high: high The upper limit value
    /// - returns: Boolean on whether the value is within the range of the limits.
    public func inRange(_ low: Int, _ high: Int) -> Bool {
        (low <= self && self <= high)
    }

    /// Returns the start IndexPath of the section interpreted by the integer.
    ///
    ///     2.sectionPath // IndexPath(row: 0, section: 2)
    ///
    public var sectionPath: IndexPath {
        IndexPath(row: 0, section: self)
    }

    /// Returns an IndexPath using the integer as a row number, in a specific section.
    ///
    /// - parameter section: The section number. Default is 0.
    /// - returns: An IndexPath with the integer as row in provided section.
    public func row(inSection section: Int = 0) -> IndexPath {
        IndexPath(row: Int(self), section: section)
    }

    /// Alias for `row(inSection: 0)`. Returns an IndexPath using the integer as a row number.
    public var row: IndexPath {
        row(inSection: 0)
    }

    /**
     Breaks the total number of seconds into groupings of hours, minutes and remaining seconds.
     ````
     9999.secondsDecompose
     // => (hours 2, minutes 46, seconds 39)

     parts.hours // 2
     parts.minutes // 46
     parts.seconds // 39

     ````
     */
    public var secondsDecompose: (hours: Int, minutes: Int, seconds: Int) {
        let secs = self
        let hours = secs / 3600
        let minutes = (secs % 3600) / 60
        let seconds = (secs % 3600) % 60
        return (hours, minutes, seconds)
    }

    /// Returns time as a set of hours, minutes and seconds separated by ':' (ex "01:55").
    public var secondsToClockFormat: String {
        Double(self).secondsToClockFormat
    }
}

extension FloatingPoint {
    /// Turns the number from degrees into radian value
    ///
    /// You can also use the degree symbol using (Option + Shift + 8).
    /// ```
    ///    35.degress == 35°
    /// ```
    public var degreesToRadians: Self { self * .pi / 180 }
    /// Turns the number from radians into a degree value
    public var radiansToDegrees: Self { self * 180 / .pi }
}

// MARK: Double extensions

extension Double {
    /// Round to a specific number of decimal places.
    /// ```
    ///    1.23556789.roundTo(3) // 1.236
    /// ```
    /// - parameter decimalPlaces: The number decimal places to keep.
    public func roundTo(_ decimalPlaces: Int) -> Double {
        let divisor = pow(10.0, Double(decimalPlaces))
        return (self * divisor).rounded() / divisor
    }

    /// Return the radian value using the number as degrees.
    ///
    /// You can also use the degree symbol using (Option + Shift + 8).
    /// ```
    ///    35.degress == 35°
    /// ```
    public var degrees: CGFloat { CGFloat(self * .pi / 180.0) }

    /**
      Breaks the total number of seconds into groupings of hours, minutes and remaining seconds.
     ````
      let seconds = 9999.3
      let parts = seconds.secondsDecompose
      // => (hours 2, minutes 46, seconds 39)

      parts.hours // 2
      parts.minutes // 46
      parts.seconds // 39

     ````
     */
    public var secondsDecompose: (hours: Int, minutes: Int, seconds: Int) {
        return Int(self).secondsDecompose
    }

    /// Returns the number of bytes expressed using current value as MBs.
    public var MBs: Double { self * 1024 * 1024 }

    /// Returns a random Double value less than the current value.
    public var random: Double {
        Double(arc4random_uniform(UInt32(self)))
    }

    /// Convert the amount to meters if we intepret it as miles.
    public var milesToMeters: Double {
        1609.0 * self
    }

    /// Returns time as a set of hours, minutes and seconds separated by ':' (ex "01:55").
    ///
    ///     9999.3.secondsToClockFormat // "2:46:39"
    ///     458.secondsToClockFormat // "7:38"
    public var secondsToClockFormat: String {
        if isNaN || isInfinite {
            return "0:00"
        }
        let seconds = Int(truncatingRemainder(dividingBy: 60))
        let minutes = Int((self / 60).truncatingRemainder(dividingBy: 60))
        let hours = Int(self / 3600)
        let secondsString = String.localizedStringWithFormat("%02d", abs(seconds))

        if hours > 0 {
            return "\(hours):" + String.localizedStringWithFormat("%02d", abs(minutes)) + ":\(secondsString)"
        }
        return "\(minutes):\(secondsString)"
    }

    /// Rounds the value to a number of decimal places.
    ///
    ///     let rounded = 12.3456.places(2) // 12.34
    ///
    /// - Parameter places: The number of decimal places to round to.
    public func places(_ places: Int) -> Double {
        if places < 1 { return rounded() }
        let scaler = Double(truncating: pow(10, places) as NSNumber)
        let inflated = self * scaler
        return Double(inflated.rounded() / scaler)
    }
}

extension Substring {
    /// Recast substring as string
    public var string: String? {
        String(self)
    }
}

// MARK: Optional extensions

extension Optional {
    /// Returns true if the optional can unwrap to a value
    public var hasValue: Bool {
        switch self {
        case .some:
            return true
        case _:
            return false
        }
    }

    /// Returns true if the optional is .None (nil)
    public var isNil: Bool {
        switch self {
        case .none:
            return true
        case _:
            return false
        }
    }
}

// MARK: String extensions

extension String {
    /// Return only the digits (concatenated) of the string.
    /// ## Example
    ///     "(123) 210-1981".digits // => 1232101981
    ///     "ABC123DEF456".digits // => 123456
    public var digits: String {
        components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
    }

    /// Returns whether the string is a valid email address.
    /// It currently uses this regular expression:
    ///
    ///     [A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}
    public var isValidEmail: Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"

        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }

    /// Removes whitespace from both ends of a string using `CharacterSet.whitespacesAndNewlines`
    public var trimmed: String {
        trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    /// Creates a URL object from the contents of the string
    public var url: URL? {
        URL(string: self)
    }

    /// Creates a file URL object from the contents of the string
    public var fileUrl: URL? {
        URL(fileURLWithPath: self)
    }

    /// Returns the first character in the string.
    public var first: String {
        String(self[startIndex])
    }

    /// Returns the last character in the string
    public var last: String {
        String(self[index(before: endIndex)])
    }

    /// Returns a trimmed non-blank string if availble
    public var sanitized: String? {
        let t = trimmed
        return t.isEmpty ? nil : t
    }

    /// Returns the current string with the first letter in lowercase.
    public var downcasingFirst: String {
        prefix(1).lowercased() + dropFirst()
    }

    /// Returns the current string with the first letter in uppercase.
    public var uppercasingFirst: String {
        prefix(1).uppercased() + dropFirst()
    }

    /// Remove characters from the string contained in the character set.
    ///
    /// - Parameter forbiddenChars: The characters to remove
    /// - Returns: A string not containing the characters in the set.
    public func removeCharacters(from forbiddenChars: CharacterSet) -> String {
        let passed = unicodeScalars.filter { !forbiddenChars.contains($0) }
        return String(String.UnicodeScalarView(passed))
    }

    /// Remove a set of characters from a string.
    /// ## Example
    ///
    ///     let name = "Moder/nistik: .@2@01.6"
    ///     name.removeCharacters(from: "@./")
    ///
    ///     name // => "Modernistik: 2016"
    ///
    /// - Parameter chartSet: A string containing the characters to remove
    /// - Returns: A string not containing characters in the input string.
    public func removeCharacters(from chartSet: String) -> String {
        removeCharacters(from: CharacterSet(charactersIn: chartSet))
    }

    /// Returns true if this is a non-empty string.
    public var isPresent: Bool {
        !isEmpty
    }

    /// Returns utf8 encoded data.
    public var utf8Data: Data? {
        data(using: .utf8)
    }

    /// Alias  of `contains() == false`
    public func missing(_ character: Character) -> Bool {
        contains(character) == false
    }

    /// Alias  of `contains() == false`
    public func missing<T: StringProtocol>(_ other: T) -> Bool {
        contains(other) == false
    }
}

extension String {
    /// Return the recommended height required to render the text given a width constraint and UIFont.
    ///
    /// - parameter width: The maximum width allowed to contain the text.
    /// - parameter font: The font that will be used when rendering text (and used in calculation)
    /// - returns: the minimum height required to render the text
    public func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = (self as NSString).boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return boundingBox.height
    }

    /// Return the recommended width required to render the text given a height constraint and UIFont.
    ///
    /// - parameter height: The maximum height allowed to contain the text.
    /// - parameter font: The font that will be used when rendering text (and used in calculation)
    /// - returns: the minimum width required to render the text
    public func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = (self as NSString).boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)

        return boundingBox.width
    }
}

extension NSAttributedString {
    /// Return the recommended height required to render the attributed text given a width constraint.
    ///
    /// - parameter width: The maximum width allowed to contain the text.
    /// - returns: the minimum height required to render the text
    public func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)

        return boundingBox.height
    }

    /// Return the recommended width required to render the attributed text given a height constraint.
    ///
    /// - parameter height: The maximum height allowed to contain the text.
    /// - returns: the minimum width required to render the text
    public func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)

        return boundingBox.width
    }
}

extension Optional where Wrapped == String {
    /// Returns true of the optional string is nil or the underlying value is an empty string.
    public var isEmpty: Bool {
        self?.isEmpty ?? true
    }

    /// Returns true of the optional string is a non-empty string.
    public var isPresent: Bool {
        !isEmpty
    }
}

extension Optional where Wrapped == [Any] {
    /// Returns true of the optional string is nil or the underlying value is an empty array.
    public var isEmpty: Bool {
        self?.isEmpty ?? true
    }

    /// Returns true of the optional string is a non-empty array.
    public var isPresent: Bool {
        !isEmpty
    }
}

extension Optional where Wrapped == String {
    /// Returns the string if it's not an empty string, otherwise nil.
    public var presence: String? {
        guard let s = self else { return nil }
        return s.presence
    }
}

extension String {
    /// Returns the string if it's not an empty string.
    public var presence: String? {
        let s = trimmed
        return s.isEmpty ? nil : s
    }

    /// Returns the current string in camel-case form.
    public var camelized: String {
        if isEmpty { return "" }

        let parts = components(separatedBy: CharacterSet.alphanumerics.inverted)
        guard let firstPart = parts.first else { return self }

        let first = String(describing: firstPart).downcasingFirst
        let rest = parts.dropFirst().map { String($0).uppercasingFirst }

        return ([first] + rest).joined(separator: "")
    }
}

extension StringProtocol where Self: RangeReplaceableCollection {
    /// Returns a string with all whitespace and newlines removed.
    public var removingAllWhitespacesAndNewlines: Self {
        filter { !$0.isNewline && !$0.isWhitespace }
    }

    /// Removes all whitespace and newlines removed from the current string.
    public mutating func removeAllWhitespacesAndNewlines() {
        removeAll { $0.isNewline || $0.isWhitespace }
    }
}

extension Data {
    /// Returns a string representation of the data in UTF-8 encoding.
    public var utf8String: String? {
        String(data: self, encoding: .utf8)
    }

    public var hexString: String {
        map { String(format: "%02.2hhx", $0) }.joined()
    }
}

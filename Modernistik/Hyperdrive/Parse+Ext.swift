//
//  Modernistik
//  Copyright © 2016 Modernistik LLC. All rights reserved.
//

import Parse
import TimeZoneLocate

extension PFObject {

    /// Converts the object into a pointer dictionary.
    public var pointer: [String:Any?]? {
        assert(objectId != nil, "Tried to encode a pointer with no objectId.")
        guard let o = objectId else { return nil }
        return ["__type": "Pointer", "className": parseClassName, "objectId": o]
    }

    /// Returns `true` if this object does not have an objectId.
    public var isNew:Bool {
        return objectId == nil
    }
}

// MARK: - Equatable
extension PFObject {
    
    /// Allows for checking if two Parse objects are equal.
    ///
    /// - Parameter object: The object to test against.
    /// - Returns: `true` if both objects are equal using the `==` operator.
    open override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? PFObject else { return false }
        return self == object
    }
    
    /// Compares two Parse objects by checking their objectId field and their class type.
    ///
    /// - Parameters:
    ///   - x: A Parse object..
    ///   - y: A Parse object
    /// - Returns: `true` if both objects represent the same record.
    public static func ==(x:PFObject, y:PFObject) -> Bool {
        return x.objectId == y.objectId && x.objectId != nil && type(of: x) == type(of: y)
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

/// Adds an extensions to an arrays containing PFObject subclasses.
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

//
//  Defaults.swift
//  Modernistik
//
//  Created by Anthony Persaud on 4/7/20.
//

import Foundation

@propertyWrapper
public struct Defaults<Value> {
    let key: String
    let defaultValue: Value
    var storage = UserDefaults.standard

//    public init(wrappedValue: Value) {
//        key = wrappedValue
//    }

    public init(_ key: String, fallback: Value) {
        self.key = key
        defaultValue = fallback
    }

    public var wrappedValue: Value {
        get {
            storage.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            if newValue == nil {
                storage.removeObject(forKey: key)
            } else {
                storage.set(newValue, forKey: key)
            }
        }
    }
}

extension Defaults where Value == Bool {
    public init(_ key: String) {
        self.key = key
        defaultValue = false
    }
}

extension Defaults where Value: ExpressibleByNilLiteral {
    public init(key: String) {
        self.init(key, fallback: nil)
    }
}

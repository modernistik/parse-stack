//
//  Defaults.swift
//  Modernistik
//
//  Created by Anthony Persaud on 4/7/20.
//

import Foundation

@propertyWrapper
public struct Defaults<Value> {
    public let key: String
    public let defaultValue: Value
    public var storage = UserDefaults.standard

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
            storage.set(newValue, forKey: key)
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
    public init(_ key: String) {
        self.init(key, fallback: nil)
    }
}

extension Defaults where Value == String {
    public init(_ key: String) {
        self.key = key
        defaultValue = ""
    }
}

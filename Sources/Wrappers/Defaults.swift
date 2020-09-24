//
//  Defaults.swift
//  Modernistik
//
//  Created by Anthony Persaud on 4/7/20.
//

import Foundation

@propertyWrapper
/// A property wrapper that proxies storage to UserDefaults.standard.
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
            if let value = newValue as? OptionalType, value.isNil {
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
    public init(_ key: String) {
        self.key = key
        defaultValue = nil
    }
}

extension Defaults where Value == String {
    public init(_ key: String) {
        self.key = key
        defaultValue = ""
    }
}

extension Defaults where Value == Int {
    public init(_ key: String) {
        self.key = key
        defaultValue = 0
    }
}

extension Defaults where Value == Double {
    public init(_ key: String) {
        self.key = key
        defaultValue = 0.0
    }
}

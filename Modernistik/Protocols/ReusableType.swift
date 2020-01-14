//
//  Protocols.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

/// An object that has a rawValue type that returns an Int.
public protocol IntRepresentable {
    var rawValue: Int { get }
}

/// An object that has a rawValue type that returns a String.
public protocol StringRepresentable {
    var rawValue: String { get }
}

/** Protocol that requires the implementor to have a `reuseIdentifier` field.
    This is normally implemented by items that will go through a recycling phase like `UITableViewCell` or `UICollectionViewCell`.
 # Discussion:
 We have defined an extension to this protocol which automatically returns the name of the class as the
 default implementation of this property.
 */
public protocol ReusableType {
    static var reuseIdentifier: String { get }
}

extension ReusableType {
    /// Return the reuseIdentifier for this object. By default it is their class name.
    public static var reuseIdentifier: String {
        return String(describing: Self.self)
    }
}

extension ReusableType where Self: UITableViewCell {
    public static func register(with tableView: UITableView, withIdentifier reuseIdentifier: String = String(describing: Self.self)) {
        tableView.register(Self.self, forCellReuseIdentifier: reuseIdentifier)
    }

    public static func dequeueReusableCell(in tableView: UITableView, withIdentifier reuseIdentifier: String = String(describing: Self.self)) -> Self {
        if let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? Self {
            return cell
        }
        assertionFailure("TableView misconfigured! Failed dequeueing of \(reuseIdentifier)")
        return Self()
    }

    public static func dequeueReusableCell(inTableView tableView: UITableView, forIndexPath indexPath: IndexPath) -> Self {
        let ident = String(describing: Self.self)
        if let cell = tableView.dequeueReusableCell(withIdentifier: ident, for: indexPath) as? Self {
            return cell
        }
        assertionFailure("TableView misconfigured! Failed dequeueing of \(ident)")
        return Self()
    }
}

extension ReusableType where Self: UITableViewHeaderFooterView {
    public static func register(with tableView: UITableView, withIdentifier reuseIdentifier: String = String(describing: Self.self)) {
        tableView.register(Self.self, forHeaderFooterViewReuseIdentifier: reuseIdentifier)
    }

    public static func dequeueReusableHeaderFooterView(in tableView: UITableView, withIdentifier reuseIdentifier: String = String(describing: Self.self)) -> Self {
        if let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: reuseIdentifier) as? Self {
            return cell
        }
        assertionFailure("TableHeaderFooterView misconfigured! Failed dequeueing of \(reuseIdentifier)")
        return Self()
    }

    public static func dequeueReusableHeaderFooterView(in tableView: UITableView) -> Self {
        let ident = String(describing: Self.self)

        if let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: ident) as? Self {
            return cell
        }
        assertionFailure("TableHeaderFooterView misconfigured! Failed dequeueing of \(ident)")
        return Self()
    }
}

extension ReusableType where Self: UICollectionViewCell {
    public static func register(with collectionView: UICollectionView, withIdentifier reuseIdentifier: String = String(describing: Self.self)) {
        collectionView.register(Self.self, forCellWithReuseIdentifier: reuseIdentifier)
    }

    public static func dequeueReusableCell(in collectionView: UICollectionView, for indexPath: IndexPath, reuseIdentifier: String = String(describing: Self.self)) -> Self {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? Self {
            return cell
        }
        assertionFailure("CollectionView misconfigured! Failed dequeueing of \(reuseIdentifier)")
        return Self()
    }
}

extension ReusableType where Self: UICollectionReusableView {
    public static func register(with collectionView: UICollectionView, forSupplementaryViewOfKind kind: String, withIdentifier reuseIdentifier: String = String(describing: Self.self)) {
        collectionView.register(Self.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: reuseIdentifier)
    }

    public static func dequeueReusableSupplementaryView(ofKind elementKind: String, in collectionView: UICollectionView, for indexPath: IndexPath, reuseIdentifier: String = String(describing: Self.self)) -> Self {
        if let view = collectionView.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: reuseIdentifier, for: indexPath) as? Self {
            return view
        }
        assertionFailure("UICollectionReusableView misconfigured! Failed dequeueing of \(reuseIdentifier)")
        return Self()
    }
}

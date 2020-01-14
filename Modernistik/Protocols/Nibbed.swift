//
//  Nibbed.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

/// Provides an interface for views who need to be loaded from nib/xib files.
public protocol Nibbed {
    static var nib: UINib { get }
}

extension Nibbed where Self: ReusableType, Self: UIView {
    /// Load a UINib object for the current view based on the view name.
    public static var nib: UINib {
        return UINib(nibName: String(describing: Self.self), bundle: nil)
    }

    /// Load the proper view subclass from its corresponding nib/xib in the main bundle.
    public static func nibView(owner: AnyObject) -> Self {
        let ident = String(describing: Self.self)
        if let view = Bundle.main.loadNibNamed(ident, owner: owner, options: nil)?.first as? Self {
            return view
        }
        assertionFailure("Invalid Nib loading configuration for \(ident)")
        return Self()
    }
}

extension Nibbed where Self: UITableViewCell, Self: ReusableType {
    /// Registers the table cell class using the registered nib file.
    public static func registerNib(with tableView: UITableView) {
        tableView.register(Self.nib, forCellReuseIdentifier: String(describing: Self.self))
    }
}

extension Nibbed where Self: UICollectionViewCell, Self: ReusableType {
    /// Registers the collection cell class using the registered nib file.
    public static func registerNib(with collectionView: UICollectionView) {
        collectionView.register(Self.nib, forCellWithReuseIdentifier: String(describing: Self.self))
    }
}

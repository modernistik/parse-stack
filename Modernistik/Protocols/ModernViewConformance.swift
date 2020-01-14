//
//  ModernViewConformance.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

/** Basic protocol for following a standard lifecycle of calls for UIView subclasses. This
 is the starting point for most view classes. Normally, you do not have to conform to this protocol
 and you would use one of the concrete subclasses. The three methods that need implementation are:

 ```
 func setupView() {
    // code to setup subviews and layout
 }

 func updateInterface() {
    // code to update the interface
 }

 func prepareForReuse() {
    // code to reset the view.
    // this method is already present
    // in UITableViewCell and UICollectionViewCell
 }
 ```
 */
public protocol ModernViewConformance: AnyObject {
    /// This method, called once in the view's lifecycle, should implement
    /// setting up the view's children in the parent's view. This method will be called
    /// when the view is instantiated programmatically or through a storyboard.
    func setupView()

    /// This method should implement setting up the autolayout constraints, if any, for the subviews that
    /// were added in `setupView()`. This method should only be called once in the view's lifecycle, normally before
    /// a layout pass.
    ///
    /// - note: The default implementation does nothing. Do not call `setNeedsUpdateConstraints()` inside
    /// your implementation. Calling `setNeedsUpdateConstraints()` may schedule another update pass, creating a feedback loop.
    /// - note: If you do not want to inherit the parent's layout constraints in your subclass, you should not
    /// call the super implementation.
    func setupConstraints()

    /// This method, should implement changes in the view's interface.
    ///
    /// - note: The default implementation does nothing.
    func updateInterface()

    /// This method, should implement resetting any view properties or subviews
    /// when it is going through view recycling, for example, cells in a table view.
    /// - note: The default implementation does nothing.
    func prepareForReuse()
}

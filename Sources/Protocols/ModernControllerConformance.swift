//
//  ModernControllerConformance.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

/** Basic protocol that most application controllers should adopt. Normally you would not implement
 this protocol and instead subclass `ModernViewController` which provides extension and functionality.
 This protocol defines two methods:
 ```
 func setupConstraints() {
    // code to setup view constraints
 }

 func updateInterface() {
 // code to update the interface based on some state or action change.
 }
 ```
 */
public protocol ModernControllerConformance: AnyObject {
    /**
     This method will be called once as part of the view controller
     lifecycle, in order for the controller to setup its autolayout
     constraints and add them to the view controller's view property.

     - note: If you do not want to inherit the parent's layout constraints in your subclass, you should not
     call super.
     */
    func setupConstraints()

    /// This method, should implement changes in the controller's view.
    ///
    /// The default implmentation of this method does nothing.
    func updateInterface()
}

// Default implementations
extension ModernControllerConformance where Self: UIViewController {
    public func setupConstraints() {}
    public func updateInterface() {}
}

//
//  ModernViewController.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

open class ModernViewController: UIViewController, ModernControllerConformance {
    private var needsSetupConstraints = true

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.setNeedsUpdateConstraints()
    }

    open func setupConstraints() {}

    open override func updateViewConstraints() {
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
        // According to Apple's doc, it should be called as the final step in the
        // implementation.
        super.updateViewConstraints()
    }

    open func updateInterface() {}
}

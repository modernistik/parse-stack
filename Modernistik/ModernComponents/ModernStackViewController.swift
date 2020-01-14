//
//  ModernStackViewController.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

open
class ModernStackViewController: ModernViewController {
    let scrollView = UIScrollView(autolayout: true)
    let stackView = ModernStackView(autolayout: true)

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        stackView.axis = .vertical
    }

    open override func setupConstraints() {
        super.setupConstraints()
        view.addConstraints(scrollView.constraintsPinned(toView: view))
        view.addConstraints(stackView.constraintsPinned(toView: scrollView))
        view.addConstraint(stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor,
                                                            constant: -(scrollView.contentInset.left + scrollView.contentInset.right)))
    }

    /// Alias to add a view to the stackView.
    /// - Parameter view: The view to add to the stack view.
    open func addArrangedSubview(_ view: UIView) {
        stackView.addArrangedSubview(view)
    }

    /// Scroll to a specific view which could be in the stack view.
    /// - Parameter view: The view to scroll to.
    open func scrollTo(view: UIView) {
        scrollView.scrollRectToVisible(view.frame, animated: true)
    }
}

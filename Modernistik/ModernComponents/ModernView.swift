//
//  ModernView.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

/// Base view class that follows the general setup/update/reuse pattern when
/// either instantiating from nibs/storyboards or code. Because it implements
/// `ModernViewConformance`, it will properly call `setupView()` whether the view
/// is instantiated through an designated initializer, storyboard or nib.
open class ModernView: UIView, ModernViewConformance {
    @objc public convenience init(square: CGFloat) {
        self.init(frame: .square(square))
    }

    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @objc public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc public required init(autolayout: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = !autolayout
        setupView()
    }

    @objc open override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    /// Method where the view should be setup once.
    @objc open func setupView() {
        backgroundColor = .clear
        setNeedsUpdateConstraints()
    }

    /// This method should implement setting up the autolayout constraints, if any, for the subviews that
    /// were added in `setupView()`. This method is only called once in the view's lifecycle in `updateConstraints()`
    /// layout pass through an internal flag.
    ///
    /// - note: Do not call `setNeedsUpdateConstraints()` inside your implementation.
    /// Calling `setNeedsUpdateConstraints()` may schedule another update pass, creating a feedback loop.
    /// - note: If you do not want to inherit the parent's layout constraints in your subclass, you should not
    /// call the super implementation.
    @objc open func setupConstraints() {}

    private var needsSetupConstraints = true
    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    /// This method should be called whenever there is a need to update the interface.
    @objc open func updateInterface() {
        setNeedsDisplay()
    }

    /// This method should be called whenever there is a need to reset the interface.
    @objc open func prepareForReuse() {}
}

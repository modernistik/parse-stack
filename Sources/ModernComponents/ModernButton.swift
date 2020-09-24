//
//  ModernButton.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

/// Provides a base UIButton class that conforms to the general design lifecycle patterns
/// of setup/update/reuse, etc. It also supports modifying the `minimumHitArea` property for
/// easily increasing the target tap frame.
open class ModernButton: UIButton, ModernViewConformance {
    public var minimumHitArea = CGSize.zero

    public convenience init(square: CGFloat) {
        self.init(frame: .square(square))
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public required init(autolayout: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = !autolayout
        setupView()
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    /// Alias for title(for: .normal) setter and getter.
    @objc open var title: String? {
        get {
            title(for: .normal)
        }
        set {
            setTitle(newValue, for: .normal)
        }
    }

    private var needsSetupConstraints = true
    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    /// Method where the view should be setup once.
    @objc open func setupView() {
        backgroundColor = .clear
        setNeedsUpdateConstraints()
    }

    @objc open func setupConstraints() {}

    /// This method should be called whenever there is a need to update the interface.
    @objc open func updateInterface() {}

    /// This method should be called whenever there is a need to reset the interface.
    @objc open func prepareForReuse() {}

    @objc open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if minimumHitArea == CGSize.zero { return super.hitTest(point, with: event) }
        // need optimization
        // if the button is hidden/disabled/transparent it can't be hit
        if isHidden || !isUserInteractionEnabled || alpha < 0.01 {
            return nil
        }

        // increase the hit frame to be at least as big as `minimumHitArea`
        let buttonSize = bounds.size
        let widthToAdd = max(minimumHitArea.width - buttonSize.width, 0)
        let heightToAdd = max(minimumHitArea.height - buttonSize.height, 0)
        let largerFrame = bounds.insetBy(dx: -widthToAdd / 2, dy: -heightToAdd / 2)

        // perform hit test on larger frame
        return (largerFrame.contains(point)) ? self : nil
    }
}

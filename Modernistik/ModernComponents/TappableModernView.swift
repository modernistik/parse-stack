//
//  TappableModernView.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

/// Provides a simple UIView that implements ModernViewConformance, which has an adjustable hit target area by modifying `minimumHitArea`, and allows for easily adding a block to be executed whenever the view is tapped.
open class TappableModernView: ModernView {
    public var minimumHitArea = CGSize.zero
    var _actionBlock: (() -> Void)?

    private var needsSetupConstraints = true
    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    open override func setupView() {
        super.setupView()
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    @objc open func tapped() {
        _actionBlock?()
    }

    open func tap(block: @escaping (() -> Void)) {
        _actionBlock = block
    }

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

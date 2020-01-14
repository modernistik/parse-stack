//
//  ModernTextView.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

/// Provides a base UITextField class that conforms to the general design lifecycle patterns
/// of setup/update/reuse, etc.
open class ModernTextView: UITextView, ModernViewConformance {
    public init(autolayout _: Bool) {
        super.init(frame: .zero, textContainer: nil)
        translatesAutoresizingMaskIntoConstraints = false
        setupView()
    }

    public override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
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
        setNeedsUpdateConstraints()
    }

    @objc open func setupConstraints() {}
    /// This method should be called whenever there is a need to update the interface.
    @objc open func updateInterface() {}

    /// This method should be called whenever there is a need to reset the interface.
    @objc open func prepareForReuse() { text = nil }
}

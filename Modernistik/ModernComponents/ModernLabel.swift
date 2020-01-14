//
//  ModernLabel.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

/// Provides a base UILabel class that conforms to the general design lifecycle patterns
/// of setup/update/reuse, etc.
open class ModernLabel: UILabel, ModernViewConformance {
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

    private var needsSetupConstraints = true
    @objc open override func updateConstraints() {
        super.updateConstraints()
        if needsSetupConstraints {
            needsSetupConstraints = false
            setupConstraints()
        }
    }

    @objc open func setupView() {
        backgroundColor = .clear
        setNeedsUpdateConstraints()
    }

    @objc open func setupConstraints() {}
    /// This method should be called whenever there is a need to update the interface.
    @objc open func updateInterface() {}

    /// This method should be called whenever there is a need to reset the interface.
    @objc open func prepareForReuse() { text = nil }
}

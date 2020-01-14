//
//  ModernCollectionCell.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

/// Provides a base UICollectionViewCell class that conforms to the general design lifecycle patterns
/// of setup/update/reuse, etc.
open class ModernCollectionCell: UICollectionViewCell, ReusableType, ModernViewConformance {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
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
        setNeedsUpdateConstraints()
    }

    @objc open func setupConstraints() {}
    @objc open func updateInterface() {}
}

//
//  ModernTableCell.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

/// Provides a base UITableViewCell class that conforms to the general design lifecycle patterns
/// of setup/update/reuse, etc.
open class ModernTableCell: UITableViewCell, ReusableType, ModernViewConformance {
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
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

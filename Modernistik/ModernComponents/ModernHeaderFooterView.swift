//
//  ModernHeaderFooterView.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

open class ModernHeaderFooterView: UITableViewHeaderFooterView, ReusableType, ModernViewConformance {
    public override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
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

//
//  ViewController.swift
//  Starter
//
//  Created by Anthony Persaud on 1/28/19.
//  Copyright © 2019 Modernistik. All rights reserved.
//

import Modernistik
import UIKit

class ViewController: ModernViewController {
    let customView = CustomView(autolayout: true)
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(customView)
    }

    override func setupConstraints() {
        super.setupConstraints()
        view.addConstraints(customView.constraintsPinned(toView: view))
    }

    override func updateInterface() {
        super.updateInterface()
    }
}

class CustomView: ModernView {
    override func setupView() {
        super.setupView()
    }

    override func setupConstraints() {
        super.setupConstraints()
    }

    override func updateInterface() {
        super.updateInterface()
    }

//    override func draw(_ rect: CGRect) {
//
//    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }
}

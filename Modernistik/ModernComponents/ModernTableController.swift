//
//  ModernTableController.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

open class ModernTableController: ModernViewController, UITableViewDataSource, UITableViewDelegate {
    public let tableView = UITableView(autolayout: true)
    open override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        ModernTableCell.register(with: tableView)
        tableView.dataSource = self
        tableView.delegate = self
    }

    open override func setupConstraints() {
        var layoutConstraints = [
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ]

        if #available(iOS 11.0, tvOS 11.0, *) {
            layoutConstraints += [
                tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ]
        } else {
            layoutConstraints += [
                tableView.topAnchor.constraint(equalTo: view.topAnchor),
                tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ]
        }
        view.addConstraints(layoutConstraints)
    }

    open func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 0
    }

    open func tableView(_ tableView: UITableView, cellForRowAt _: IndexPath) -> UITableViewCell {
        return ModernTableCell.dequeueReusableCell(in: tableView)
    }
}

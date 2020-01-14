//
//  ModernCollectionController.swift
//  Modernistik
//
//  Created by Anthony Persaud on 1/14/20.
//

import Foundation
import UIKit

open class ModernCollectionController: ModernViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    public let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    open override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        ModernCollectionCell.register(with: collectionView)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        // Do any additional setup after loading the view.
    }

    open override func setupConstraints() {
        var layoutConstraints = [
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ]
        if #available(iOS 11.0, tvOS 11.0, *) {
            layoutConstraints += [
                collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ]
        } else {
            layoutConstraints += [
                collectionView.topAnchor.constraint(equalTo: view.topAnchor),
                collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ]
        }
        view.addConstraints(layoutConstraints)
    }

    open func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return 0
    }

    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return ModernCollectionCell.dequeueReusableCell(in: collectionView, for: indexPath)
    }
}

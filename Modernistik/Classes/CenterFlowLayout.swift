//
//  Modernistik
//  Copyright © Modernistik LLC. All rights reserved.
//

import UIKit

/**
 A collection view layout classes where all items are centered around the view port of the collection view.
 ### Example ###
````
    let collectionLayout = CenterFlowLayout()
    var collectionView =  UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
 ````
 */
open class CenterFlowLayout : UICollectionViewFlowLayout {
    
    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        guard let superAttributes = super.layoutAttributesForElements(in: rect),
            let collectionView = collectionView, let flowDelegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout
            else { return nil }
        
        var rowCollections = [Float:[UICollectionViewLayoutAttributes]]()
        
        for itemAttributes in superAttributes {
            
            let midYRound = roundf( Float(itemAttributes.frame.midY) )
            let midYPlus = midYRound + 1
            let midYMinus = midYRound - 1
            
            var key:Float = Float.infinity
            
            if rowCollections[midYPlus] != nil {
                key = midYPlus
            }
            
            if rowCollections[midYMinus] != nil {
                key = midYMinus
            }
            
            if key == Float.infinity {
                key = midYRound
            }
            
            if rowCollections[key] == nil {
                rowCollections[key] = [UICollectionViewLayoutAttributes]()
            }
            
            rowCollections[key]?.append(itemAttributes)
            
        } // for loop
        
        let collectionViewWidth = collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
        let supportsInteritemSpacingCallback = flowDelegate.responds(to: #selector(UICollectionViewDelegateFlowLayout.collectionView(_:layout:minimumInteritemSpacingForSectionAt:)) )
        
        for (_, itemAttributesCollection) in rowCollections {
            let itemsInRow = CGFloat(itemAttributesCollection.count)
            var interItemSpacing = minimumInteritemSpacing
            
            if supportsInteritemSpacingCallback, let sectionIndex = itemAttributesCollection.first?.indexPath.section,
                let spacing = flowDelegate.collectionView?(collectionView, layout: self, minimumInteritemSpacingForSectionAt: sectionIndex) {
                interItemSpacing = spacing
            }
            
            let aggregateInteritemSpacing = interItemSpacing * (itemsInRow - 1.0)
            var aggregateItemWidths:CGFloat = 0
            for itemAttributes in itemAttributesCollection {
                aggregateItemWidths += itemAttributes.frame.width
            }
            
            // Build an alignment rect
            // |==|--------|==|
            let alignmentWidth = aggregateItemWidths + aggregateInteritemSpacing
            let alignmentXOffset = (collectionViewWidth - alignmentWidth) / 2.0
            
            // Adjust each item's position to be centered
            var previousFrame = CGRect.zero
            for itemAttributes in itemAttributesCollection {
                var itemFrame = itemAttributes.frame
                if previousFrame.equalTo(.zero) {
                    itemFrame.origin.x = alignmentXOffset
                } else {
                    itemFrame.origin.x = previousFrame.maxX + interItemSpacing
                }
                itemAttributes.frame = itemFrame
                previousFrame = itemFrame
            }
        }
        
        return superAttributes
    }
    
    
}

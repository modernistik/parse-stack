//
//  Modernistik
//  Copyright © Modernistik LLC. All rights reserved.
//

import Foundation
import UIKit

/** A collectionView layout class that allows for snapping between views in the collection after a user stops scrolling or dragging.
 
````
  let snapLayout = SnappingCollectionViewLayout()
  let collectionView = UICollectionView(frame: .zero, collectionViewLayout: snapLayout)
````
 - note: To make faster deceleration do `collectionView.decelerationRate = UIScrollViewDecelerationRateFast`
 */
open class SnappingCollectionViewLayout: UICollectionViewFlowLayout {
    
    override open func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity) }
        
        var offsetAdjustment = CGFloat.greatestFiniteMagnitude
        let horizontalOffset = proposedContentOffset.x + collectionView.contentInset.left
        
        let targetRect = CGRect(x: proposedContentOffset.x, y: 0, width: collectionView.bounds.size.width, height: collectionView.bounds.size.height)
        
        let layoutAttributesArray = super.layoutAttributesForElements(in: targetRect)
        
        layoutAttributesArray?.forEach({ (layoutAttributes) in
            let itemOffset = layoutAttributes.frame.origin.x
            if fabsf(Float(itemOffset - horizontalOffset)) < fabsf(Float(offsetAdjustment)) {
                offsetAdjustment = itemOffset - horizontalOffset
            }
        })
        
        return CGPoint(x: proposedContentOffset.x + offsetAdjustment, y: proposedContentOffset.y)
    }
}

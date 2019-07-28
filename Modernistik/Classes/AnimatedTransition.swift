//
//  AnimatedTransition.swift
//  Modernistik
//
//  Created by Anthony Persaud on 2/8/19.
//

import UIKit

open class AnimatedTransition : NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    
    open weak var activeTransitionContext: UIViewControllerContextTransitioning?
    open var isReversed = false
    open var duration: TimeInterval { return 0.5 }
    
    open func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        activeTransitionContext = transitionContext
        isReversed ?
            animateDismiss(using: transitionContext) :
            animatePresent(using: transitionContext)
    }
    
    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isReversed = false
        return self
    }
    
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isReversed = true
        return self
    }
    
    open func animateDismiss(using transitionContext: UIViewControllerContextTransitioning) {}
    open func animatePresent(using transitionContext: UIViewControllerContextTransitioning) {}
}

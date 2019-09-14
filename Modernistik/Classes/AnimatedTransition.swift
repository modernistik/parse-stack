//
//  AnimatedTransition.swift
//  Modernistik
//
//  Created by Anthony Persaud on 2/8/19.
//

import UIKit

open class AnimatedTransition: NSObject, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate {
    open weak var activeTransitionContext: UIViewControllerContextTransitioning?
    open var isReversed = false
    open var duration: TimeInterval { return 0.5 }

    open func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    open func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        activeTransitionContext = transitionContext
        isReversed ?
            animateDismiss(using: transitionContext) :
            animatePresent(using: transitionContext)
    }

    open func animationController(forPresented _: UIViewController, presenting _: UIViewController, source _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isReversed = false
        return self
    }

    open func animationController(forDismissed _: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isReversed = true
        return self
    }

    open func animateDismiss(using _: UIViewControllerContextTransitioning) {}
    open func animatePresent(using _: UIViewControllerContextTransitioning) {}
}

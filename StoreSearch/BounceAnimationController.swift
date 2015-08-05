//
//  BounceAnimationController.swift
//  StoreSearch
//
//  Created by Joel on 2015-08-04.
//  Copyright (c) 2015 Joel Rorseth. All rights reserved.
//

import UIKit

class BounceAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    //=========================================================================================
    //=========================================================================================
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return 0.4
    }
    
    //=========================================================================================
    //=========================================================================================
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        // transitionContext provides reference to new view controller
        if let toViewController = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) {
            if let toView = transitionContext.viewForKey(UITransitionContextToViewKey) {
                toView.frame = transitionContext.finalFrameForViewController(toViewController)
                
                let containerView = transitionContext.containerView()
                containerView.addSubview(toView)
                
                toView.transform = CGAffineTransformMakeScale(0.7, 0.7)
                
                // Animation starts here. Keyframe at different points with different scale.
                UIView.animateKeyframesWithDuration(transitionDuration(transitionContext), delay: 0.0, options: .CalculationModeCubic, animations: {
                    
                    UIView.addKeyframeWithRelativeStartTime(0.0, relativeDuration: 0.334, animations: {
                        toView.transform = CGAffineTransformMakeScale(1.2, 1.2)
                    })
                    
                    UIView.addKeyframeWithRelativeStartTime(0.334, relativeDuration: 0.333, animations: {
                        toView.transform = CGAffineTransformMakeScale(0.9, 0.9)
                    })
                    
                    UIView.addKeyframeWithRelativeStartTime(0.666, relativeDuration: 0.333, animations: {
                        toView.transform = CGAffineTransformMakeScale(1.0, 1.0)
                    })
                
                    }, completion: {
                        finished in
                        transitionContext.completeTransition(finished)
                })
            }
        }
    }
}

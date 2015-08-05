//
//  DimmingPresentationController.swift
//  StoreSearch
//
//  Created by Joel on 2015-07-31.
//  Copyright (c) 2015 Joel Rorseth. All rights reserved.
//

import UIKit

// UIPresentationController contains all logic for presenting new view controllers
// Note: This is NOT a view controller
// Presentation controller is required in order to keep the underlying view.
class DimmingPresentationController: UIPresentationController {
    
    lazy var dimmingView = GradientView(frame: CGRect.zeroRect)
    
    //=========================================================================================
    //=========================================================================================
    override func presentationTransitionWillBegin() {
        dimmingView.frame = containerView.bounds
        
        // containerView will refer to DetailViewController, 
        // insertSubview will place the dimming view between search view and detail view
        containerView.insertSubview(dimmingView, atIndex: 0)
        
        dimmingView.alpha = 0
        
        // transitionCoordinator coordinates presentation and animation controllers
        if let transitionCoordinator = presentedViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({
                _ in
                self.dimmingView.alpha = 1
            }, completion: nil)
        }
    }
    
    //=========================================================================================
    // Leave SearchViewController visible
    //=========================================================================================
    override func shouldRemovePresentersView() -> Bool {
        return false
    }
    
    //=========================================================================================
    //=========================================================================================
    override func dismissalTransitionWillBegin() {
        if let transitionCoordinator = presentedViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({
                _ in
                self.dimmingView.alpha = 0
            }, completion: nil)
        }
    }
}

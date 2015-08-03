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
    
    // Leave SearchViewController visible
    override func shouldRemovePresentersView() -> Bool {
        return false
    }
}

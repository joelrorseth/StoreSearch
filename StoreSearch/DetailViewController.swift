//
//  DetailViewController.swift
//  StoreSearch
//
//  Created by Joel on 2015-07-31.
//  Copyright (c) 2015 Joel Rorseth. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    //*****************************************************************************************
    //*************************************************************** MARK: - Interface Builder
    //*****************************************************************************************
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var kindLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var priceButton: UIButton!
    
    //=========================================================================================
    //=========================================================================================
    @IBAction func close() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //=========================================================================================
    //=========================================================================================
    @IBAction func openInStore() {
        if let url = NSURL(string: searchResult.storeURL) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    
    
    
    
    //*****************************************************************************************
    //***************************************************************** MARK: - View Controller
    //*****************************************************************************************
    
    var searchResult: SearchResult!
    var downloadTask: NSURLSessionDownloadTask?
    
    //=========================================================================================
    //=========================================================================================
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // Set this vc as delegate that will call protocol method
        modalPresentationStyle = .Custom
        transitioningDelegate = self
    }
    
    //=========================================================================================
    //=========================================================================================
    deinit {
        println("deinit \(self)")
        downloadTask?.cancel()
    }

    //=========================================================================================
    //=========================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        view.tintColor = UIColor(red: 20/255, green: 160/255, blue: 160/255, alpha: 1)
        view.backgroundColor = UIColor.clearColor()
        popupView.layer.cornerRadius = 10
        
        // Create the gesture recognizer that listens to taps in this view controller
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("close"))
        gestureRecognizer.cancelsTouchesInView = false
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
        
        if searchResult != nil {
            updateUI()
        }
    }
    
    //=========================================================================================
    //=========================================================================================
    func updateUI() {
        nameLabel.text = searchResult.name
        
        if searchResult.artistName.isEmpty {
            artistNameLabel.text = "Unknown"
        } else {
            artistNameLabel.text = searchResult.artistName
        }
        
        kindLabel.text = searchResult.kindForDisplay()
        genreLabel.text = searchResult.genre
        
        // Format currency
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        formatter.currencyCode = searchResult.currency
        
        // Prices must be converted to string for use in button
        var priceText: String
        if searchResult.price == 0 {
            priceText = "Free"
        } else if let text = formatter.stringFromNumber(searchResult.price) {
            priceText = text
        } else {
            priceText = ""
        }
        
        priceButton.setTitle(priceText, forState: .Normal) 
        
        if let url = NSURL(string: searchResult.artworkURL100) {
            downloadTask = artworkImageView.loadImageWithURL(url)
        }
    }
}





//*****************************************************************************************
//********************************************** MARK: - UIViewControllerTransitionDelegate
//*****************************************************************************************
extension DetailViewController: UIViewControllerTransitioningDelegate {
    
    //=========================================================================================
    //=========================================================================================
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController!, sourceViewController source: UIViewController) -> UIPresentationController? {
        // Tell UIKit to use DimmingPresentationController class to perform transition to DetailViewController
        return DimmingPresentationController(presentedViewController: presented, presentingViewController: presenting)
    }
    
    //=========================================================================================
    //=========================================================================================
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BounceAnimationController()
    }
    
    //=========================================================================================
    //=========================================================================================
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideOutAnimationController()
    }
}





//*****************************************************************************************
//***************************************************** MARK: - UIGestureRecognizerDelegate
//*****************************************************************************************
extension DetailViewController: UIGestureRecognizerDelegate {
    
    //=========================================================================================
    // Only returns true when the touch is on the background view
    //=========================================================================================
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return (touch.view === view)
    }
}
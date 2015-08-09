//
//  ViewController.swift
//  StoreSearch
//
//  Created by Joel on 2015-07-15.
//  Copyright (c) 2015 Joel Rorseth. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
    struct TableViewCellIdentifiers {
        static let searchResultCell = "SearchResultCell"
        static let nothingFoundCell = "NothingFoundCell"
        static let loadingCell = "LoadingCell"
    }
    
    let search = Search()
    var landscapeViewController: LandscapeViewController?
  
    
    
    
    
    //*****************************************************************************************
    //*************************************************************** MARK: - Interface Builder
    //*****************************************************************************************
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    //=========================================================================================
    //=========================================================================================
    @IBAction func segmentChanged(sender: UISegmentedControl) {
        performSearch()
    }
    
    
    
    
    //*****************************************************************************************
    //***************************************************************** MARK: - View Controller
    //*****************************************************************************************
    //=========================================================================================
    //=========================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 108, left: 0, bottom: 0, right: 0)
        tableView.rowHeight = 80
        
        // Register the nib cell
        var cellNib = UINib(nibName: TableViewCellIdentifiers.searchResultCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.searchResultCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.nothingFoundCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.nothingFoundCell)
        
        cellNib = UINib(nibName: TableViewCellIdentifiers.loadingCell, bundle: nil)
        tableView.registerNib(cellNib, forCellReuseIdentifier: TableViewCellIdentifiers.loadingCell)
        
        // Allow keyboard to appear when app starts
        searchBar.becomeFirstResponder()
    }
    
    //=========================================================================================
    //=========================================================================================
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //=========================================================================================
    // Method is invoked any time trait collection changes
    //=========================================================================================
    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        
        switch newCollection.verticalSizeClass {
            // Device is in landscape
        case .Compact:
            showLandscapeViewWithCoordinator(coordinator)
            // Device is back in portrait
        case .Regular, .Unspecified:
            hideLandscapeViewWithCoordinator(coordinator)
        }
    }
    
    //=========================================================================================
    //=========================================================================================
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowDetail" {
            let detailViewController = segue.destinationViewController as! DetailViewController
            let indexPath = sender as! NSIndexPath
            let searchResult = search.searchResults[indexPath.row]
            detailViewController.searchResult = searchResult
        }
    }
    
    //=========================================================================================
    //=========================================================================================
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...", message: "There was an error reading from the iTunes Store. Please try again.", preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(action)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    
    
    
    
    
    //*****************************************************************************************
    //***************************************************************** MARK: - Device Rotation
    //*****************************************************************************************
    //=========================================================================================
    //=========================================================================================
    func showLandscapeViewWithCoordinator(coordinator: UIViewControllerTransitionCoordinator) {
        precondition(landscapeViewController == nil)
        
        // Storyboard ID needs to be set to find view controller
        landscapeViewController = storyboard!.instantiateViewControllerWithIdentifier("LandscapeViewController") as? LandscapeViewController
        
        if let controller = landscapeViewController {
            controller.search = search
            controller.view.frame = view.bounds
            controller.view.alpha = 0
            
            // Call these methods to add a child view controller
            view.addSubview(controller.view)
            addChildViewController(controller)
            
            coordinator.animateAlongsideTransition({ _ in
                controller.view.alpha = 1
                self.searchBar.resignFirstResponder()
                
                if self.presentedViewController != nil {
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                },
                completion: { _ in
                    controller.didMoveToParentViewController(self)
            })
        }
    }
    
    //=========================================================================================
    //=========================================================================================
    func hideLandscapeViewWithCoordinator(coordinator: UIViewControllerTransitionCoordinator) {
        if let controller = landscapeViewController {
            controller.willMoveToParentViewController(nil)
            
            coordinator.animateAlongsideTransition({ _ in
                controller.view.alpha = 0
                }, completion: { _ in
                    controller.view.removeFromSuperview()
                    controller.removeFromParentViewController()
                    self.landscapeViewController = nil
            })
        }
    }
}




//*****************************************************************************************
//************************************************************* MARK: - UISearchBarDelegate
//*****************************************************************************************
extension SearchViewController: UISearchBarDelegate {
    //=========================================================================================
    // Contains closure that is called at end of performSearchForText, possibly showing error
    //=========================================================================================
    func performSearch() {
        search.performSearchForText(searchBar.text, category: segmentedControl.selectedSegmentIndex, completion: { success in
            if !success {
                self.showNetworkError()
            }
            self.tableView.reloadData()
        })
        
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }
    
    //=========================================================================================
    //=========================================================================================
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        performSearch()
    }
    
    //=========================================================================================
    //=========================================================================================
    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .TopAttached
    }
}





//*****************************************************************************************
//*********************************************************** MARK: - UITableViewDataSource
//*****************************************************************************************
extension SearchViewController: UITableViewDataSource {
    //=========================================================================================
    //=========================================================================================
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if search.isLoading {
            return 1
        } else if !search.hasSearched {
            return 0
        } else if search.searchResults.count == 0 {
            return 1
        } else {
            return search.searchResults.count
        }
    }
    
    //=========================================================================================
    //=========================================================================================
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Cell is loading
        if search.isLoading {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.loadingCell, forIndexPath: indexPath) as! UITableViewCell
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            
            return cell
        } else if search.searchResults.count == 0 {
            return tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.nothingFoundCell, forIndexPath: indexPath) as! UITableViewCell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.searchResultCell, forIndexPath: indexPath) as! SearchResultCell
            
            let searchResult = search.searchResults[indexPath.row]
            cell.configureForSearchResult(searchResult)
            
            return cell
        }
    }
}





//*****************************************************************************************
//************************************************************* MARK: - UITableViewDelegate
//*****************************************************************************************
extension SearchViewController: UITableViewDelegate {
    //=========================================================================================
    //=========================================================================================
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        // Send along the index path for use in prepareForSegue
        performSegueWithIdentifier("ShowDetail", sender: indexPath)
    }
    
    //=========================================================================================
    // Make sure you can only select rows with results
    //=========================================================================================
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if search.searchResults.count == 0 || search.isLoading {
            return nil
        } else {
            return indexPath
        }
    }
}

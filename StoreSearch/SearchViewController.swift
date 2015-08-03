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
    
    var searchResults = [SearchResult]()
    var hasSearched = false
    var isLoading = false
    var dataTask: NSURLSessionDataTask?
  
    
    
    
    
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
    //=========================================================================================
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowDetail" {
            let detailViewController = segue.destinationViewController as! DetailViewController
            let indexPath = sender as! NSIndexPath
            let searchResult = searchResults[indexPath.row]
            detailViewController.searchResult = searchResult
        }
    }
    
    
    
    
    
    //*****************************************************************************************
    //*********************************************************************** MARK: - Searching
    //*****************************************************************************************
    //=========================================================================================
    // Form the requested url based on search bar input
    //=========================================================================================
    func urlWithSearchText(searchText: String, category: Int) -> NSURL {
        var entityName: String
        switch category {
        case 1: entityName = "musicTrack"
        case 2: entityName = "software"
        case 3: entityName = "ebook"
        default: entityName = ""
        }
        
        let escapedSearchText = searchText.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let urlString = String(format: "http://itunes.apple.com/search?term=%@&limit=200&entity=%@", escapedSearchText, entityName)
        let url = NSURL(string: urlString) // Failable initializer
        return url!
    }
    
    //=========================================================================================
    // Use NSJSONSerialization to convert JSON search results to a dictionary
    //=========================================================================================
    func parseJSON(data: NSData) -> [String: AnyObject]? {
        var error: NSError?
        
        if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error) as? [String: AnyObject] {
            return json
        } else if let error = error {
            println("JSON Error: \(error)")
        } else {
            println("Unknown JSON Error")
        }
        
        return nil
    }
    
    //=========================================================================================
    //=========================================================================================
    func showNetworkError() {
        let alert = UIAlertController(title: "Whoops...", message: "There was an error reading from the iTunes Store. Please try again.", preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(action)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    //=========================================================================================
    // Figure out which type of result is given then call it's parse method
    //=========================================================================================
    func parseDictionary(dictionary: [String: AnyObject]) -> [SearchResult] {
        // Create an array to store all of the results formed in this for loop
        var searchResults = [SearchResult]()
        
        if let array: AnyObject = dictionary["results"] {
            
            // Look at each of the array's elements in a for loop
            for resultDict in array as! [AnyObject] {
                
                // Cast objects to the right type to make sure they actually represent a dictionary
                if let resultDict = resultDict as? [String: AnyObject] {
                    
                    // Check wrapperType then create SearchResult object
                    var searchResult: SearchResult?
                    if let wrapperType = resultDict["wrapperType"] as? NSString {
                        
                        switch wrapperType {
                        case "track":
                            searchResult = parseTrack(resultDict)
                        case "audiobook":
                            searchResult = parseAudioBook(resultDict)
                        case "software":
                            searchResult = parseSoftware(resultDict)
                        default:
                            break
                        }
                    } else if let kind = resultDict["kind"] as? NSString {
                        if kind == "ebook" {
                            searchResult = parseEBook(resultDict)
                        }
                    }
                    
                    if let result = searchResult {
                        searchResults.append(result)
                    }
                }
            }
        }
        return searchResults
    }
    
    //=========================================================================================
    //=========================================================================================
    func parseTrack(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["trackPrice"] as? NSNumber {
            searchResult.price = Double(price)
        }
        if let genre = dictionary["primaryGenreName"] as? NSString {
            searchResult.genre = genre as String
        }
        return searchResult
    }

    //=========================================================================================
    //=========================================================================================
    func parseAudioBook(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["collectionName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["collectionViewUrl"] as! String
        searchResult.kind = "audiobook"
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["collectionPrice"] as? NSNumber {
            searchResult.price = Double(price)
        }
        if let genre = dictionary["primaryGenreName"] as? NSString {
            searchResult.genre = genre as String
        }
        return searchResult
    }
    
    //=========================================================================================
    //=========================================================================================
    func parseSoftware(dictionary: [String: AnyObject]) -> SearchResult {
            let searchResult = SearchResult()
            
            searchResult.name = dictionary["trackName"] as! String
            searchResult.artistName = dictionary["artistName"] as! String
            searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
            searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
            searchResult.storeURL = dictionary["trackViewUrl"] as! String
            searchResult.kind = dictionary["kind"] as! String
            searchResult.currency = dictionary["currency"] as! String
            
            if let price = dictionary["price"] as? NSNumber {
                searchResult.price = Double(price)
            }
            if let genre = dictionary["primaryGenreName"] as? NSString {
                searchResult.genre = genre as String
            }
            return searchResult
    }
    
    //=========================================================================================
    //=========================================================================================
    func parseEBook(dictionary: [String: AnyObject]) -> SearchResult {
        let searchResult = SearchResult()
        
        searchResult.name = dictionary["trackName"] as! String
        searchResult.artistName = dictionary["artistName"] as! String
        searchResult.artworkURL60 = dictionary["artworkUrl60"] as! String
        searchResult.artworkURL100 = dictionary["artworkUrl100"] as! String
        searchResult.storeURL = dictionary["trackViewUrl"] as! String
        searchResult.kind = dictionary["kind"] as! String
        searchResult.currency = dictionary["currency"] as! String
        
        if let price = dictionary["price"] as? NSNumber {
            searchResult.price = Double(price)
        }
        if let genres: AnyObject = dictionary["genres"] {
            searchResult.genre = ", ".join(genres as! [String])
        }
        return searchResult
    }
}




//*****************************************************************************************
//************************************************************* MARK: - UISearchBarDelegate
//*****************************************************************************************
extension SearchViewController: UISearchBarDelegate {
    //=========================================================================================
    //=========================================================================================
    func performSearch() {
        if !searchBar.text.isEmpty {
            searchBar.resignFirstResponder()
            
            dataTask?.cancel() // Reset if needed
            isLoading = true
            tableView.reloadData()
            
            hasSearched = true
            searchResults = [SearchResult]()
            
            let url = self.urlWithSearchText(searchBar.text, category: segmentedControl.selectedSegmentIndex)
            let session = NSURLSession.sharedSession()
            
            // Create data task for sending HTTP GET requests to the server at 'url'
            dataTask = session.dataTaskWithURL(url, completionHandler: {
                data, response, error in
                
                // Quck way to check if completionHandler is performing on main thread
                println("On the main thread? " + (NSThread.currentThread().isMainThread ? "Yes" : "No"))
                
                if let error = error {
                    println("Failure! \(error)")
                    if error.code == -999 { return }
                    
                } else if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        
                        if let dictionary = self.parseJSON(data) {
                            self.searchResults = self.parseDictionary(dictionary)
                            self.searchResults.sort(<)
                            
                            // UIKit code must be performed on main thread / queue
                            dispatch_async(dispatch_get_main_queue()) {
                                self.isLoading = false
                                self.tableView.reloadData()
                            }
                            // Exit the closure if successful
                            return
                        }
                    } else {
                        println("Failure \(response)")
                    }
                }
                
                // Must be done on main thread
                dispatch_async(dispatch_get_main_queue()) {
                    self.hasSearched = false
                    self.isLoading = false
                    self.tableView.reloadData()
                    self.showNetworkError()
                }
            })
            
            // Send the request to the server (automatically on background thread)
            dataTask?.resume()
        }
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
        if isLoading {
            return 1
        } else if !hasSearched {
            return 0
        } else if searchResults.count == 0 {
            return 1
        } else {
            return searchResults.count
        }
    }
    
    //=========================================================================================
    //=========================================================================================
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // Cell is loading
        if isLoading {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.loadingCell, forIndexPath: indexPath) as! UITableViewCell
            let spinner = cell.viewWithTag(100) as! UIActivityIndicatorView
            spinner.startAnimating()
            
            return cell
        } else if searchResults.count == 0 {
            return tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.nothingFoundCell, forIndexPath: indexPath) as! UITableViewCell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(TableViewCellIdentifiers.searchResultCell, forIndexPath: indexPath) as! SearchResultCell
            
            let searchResult = searchResults[indexPath.row]
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
        if searchResults.count == 0 || isLoading {
            return nil
        } else {
            return indexPath
        }
    }
}

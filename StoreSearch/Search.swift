//
//  Search.swift
//  StoreSearch
//
//  Created by Joel on 2015-08-09.
//  Copyright (c) 2015 Joel Rorseth. All rights reserved.
//

import Foundation
import UIKit

// SearchComplete is a closure that takes Bool parameter and returns no value
typealias SearchComplete = (Bool) -> Void

class Search {
    
    private var dataTask: NSURLSessionDataTask? = nil
    private(set) var state: State = .NotSearchedYet
    
    enum Category: Int {
        case All = 0
        case Music = 1
        case Software = 2
        case EBook = 3
        
        var entityName: String {
            switch self {
            case .Music: return "musicTrack"
            case .Software: return "software"
            case .EBook: return "ebook"
            case .All: return ""
            }
        }
    }
    
    enum State {
        case NotSearchedYet
        case Loading
        case NoResults
        case Results([SearchResult]) // associated value
    }
    
    
    //=========================================================================================
    //=========================================================================================
    func performSearchForText(text: String, category: Category, completion: SearchComplete) {
        if !text.isEmpty {
            dataTask?.cancel() // Reset if needed
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            state = .Loading
            
            let url = urlWithSearchText(text, category: category)
            let session = NSURLSession.sharedSession()
            
            // Create data task for sending HTTP GET requests to the server at 'url'
            dataTask = session.dataTaskWithURL(url, completionHandler: {
                data, response, error in
                
                self.state = .NotSearchedYet
                var success = false
                
                // Quck way to check if completionHandler is performing on main thread
                println("On the main thread? " + (NSThread.currentThread().isMainThread ? "Yes" : "No"))
                
                if let error = error {
                    println("Failure! \(error)")
                    if error.code == -999 { return }
                    
                } else if let httpResponse = response as? NSHTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        
                        if let dictionary = self.parseJSON(data) {
                            var searchResults = self.parseDictionary(dictionary)
                            if searchResults.isEmpty {
                                self.state = .NoResults
                            } else {
                                searchResults.sort(<)
                                self.state = .Results(searchResults)
                            }
                            success = true
                        }
                    }
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    
                    // Pass true or false to completion when it is called here
                    completion(success)
                }
            })
            
            dataTask?.resume()
        }
        
    }
    
    //=========================================================================================
    // Form the requested url based on search bar input
    //=========================================================================================
    private func urlWithSearchText(searchText: String, category: Category) -> NSURL {
        var entityName = category.entityName
        
        let escapedSearchText = searchText.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        let urlString = String(format: "http://itunes.apple.com/search?term=%@&limit=200&entity=%@", escapedSearchText, entityName)
        let url = NSURL(string: urlString) // Failable initializer
        return url!
    }
    
    //=========================================================================================
    // Use NSJSONSerialization to convert JSON search results to a dictionary
    //=========================================================================================
    private func parseJSON(data: NSData) -> [String: AnyObject]? {
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
    // Figure out which type of result is given then call it's parse method
    //=========================================================================================
    private func parseDictionary(dictionary: [String: AnyObject]) -> [SearchResult] {
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
    private func parseTrack(dictionary: [String: AnyObject]) -> SearchResult {
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
    private func parseAudioBook(dictionary: [String: AnyObject]) -> SearchResult {
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
    private func parseSoftware(dictionary: [String: AnyObject]) -> SearchResult {
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
    private func parseEBook(dictionary: [String: AnyObject]) -> SearchResult {
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

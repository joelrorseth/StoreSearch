//
//  SearchResult.swift
//  StoreSearch
//
//  Created by Joel on 2015-07-16.
//  Copyright (c) 2015 Joel Rorseth. All rights reserved.
//

import Foundation

// Operator Overloading
func < (lhs: SearchResult, rhs: SearchResult) -> Bool {
    return lhs.name.localizedStandardCompare(rhs.name) == NSComparisonResult.OrderedAscending
}

class SearchResult {
    var name = ""
    var artistName = ""
    var artworkURL60 = ""
    var artworkURL100 = ""
    var storeURL = ""
    var kind = ""
    var currency = ""
    var price = 0.0
    var genre = ""
}

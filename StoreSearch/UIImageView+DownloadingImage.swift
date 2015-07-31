//
//  UIImageView+DownloadingImage.swift
//  StoreSearch
//
//  Created by Joel on 2015-07-30.
//  Copyright (c) 2015 Joel Rorseth. All rights reserved.
//

import UIKit

extension UIImageView {
    
    func loadImageWithURL(url: NSURL) -> NSURLSessionDownloadTask {
        let session = NSURLSession.sharedSession()
        
        // Create a download task using the url and session variable (saves to temp)
        let downloadTask = session.downloadTaskWithURL(url, completionHandler: {
            [weak self] url, response, error in
            
            if error == nil && url != nil {
                // Make an image using a data file (containing url contents)
                if let data = NSData(contentsOfURL: url) {
                    if let image = UIImage(data: data) {
                        // Assign image to image property on main thread (UIKit)
                        dispatch_async(dispatch_get_main_queue()) {
                            if let strongSelf = self {
                                // self now refers to the UIImageView
                                strongSelf.image = image
                            }
                        }
                    }
                }
            }
        })
        //
        downloadTask.resume()
        return downloadTask
    }
}

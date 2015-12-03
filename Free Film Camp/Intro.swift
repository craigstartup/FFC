//
//  Intro.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 11/20/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit
import AVFoundation

class Intro: NSObject, NSCoding {
    // MARK: Properties
    var video: String!
    var image: UIImage?
    
    // MARK: Types
    struct PropertyKey {
        static let videoKey = "keyForVideo"
        static let imageKey = "keyImage"
    }
    // MARK: Initialization
    init?(video: String!, image: UIImage?) {
        // Initialize stored properties
        self.video = video
        self.image = image
        super.init()
        
        if video == nil {
            return nil
        }
    }
    
    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(video, forKey: PropertyKey.videoKey)
        aCoder.encodeObject(image, forKey: PropertyKey.imageKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let video = aDecoder.decodeObjectForKey(PropertyKey.videoKey) as! String!
        let image = aDecoder.decodeObjectForKey(PropertyKey.imageKey) as! UIImage!
        self.init(video: video, image: image)
        
        if video == nil {
            return nil
        }
    }
}

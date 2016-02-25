//
//  Scene.swift
//  Film Camp
//
//  Created by Eric Mentele on 11/5/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import AVFoundation

class Scene: NSObject, NSCoding {
    // MARK: Properties
    var shotVideos: [NSURL]
    var shotImages: [UIImage]
    var voiceOver: String
    
    // MARK: Types
    struct PropertyKey {
        static let shotVideosKey = "keyForShotVideos"
        static let shotImagesKey = "keyForShotImages"
        static let voiceOverKey = "keyForVoiceOver"
    }
    // MARK: Initialization
    init?(shotVideos: [NSURL], shotImages: [UIImage], voiceOver: String) {
        // Initialize stored properties
        self.shotVideos = shotVideos
        self.shotImages = shotImages
        self.voiceOver = voiceOver
        super.init()
    }
    
    // MARK: NSCoding
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(shotVideos, forKey: PropertyKey.shotVideosKey)
        aCoder.encodeObject(shotImages, forKey: PropertyKey.shotImagesKey)
        aCoder.encodeObject(voiceOver, forKey: PropertyKey.voiceOverKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let shotVideos = aDecoder.decodeObjectForKey(PropertyKey.shotVideosKey) as! [NSURL]
        let shotImages = aDecoder.decodeObjectForKey(PropertyKey.shotImagesKey) as! [UIImage]
        let voiceOver = aDecoder.decodeObjectForKey(PropertyKey.voiceOverKey) as! String
        
        self.init(shotVideos: shotVideos, shotImages: shotImages, voiceOver: voiceOver)
        
    }
}
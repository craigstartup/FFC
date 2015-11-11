//
//  Scene.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 11/5/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class Scene: NSObject, NSCoding {
    // MARK: Properties
    var shotVideos: [AVAsset?]?
    var shotImages: [UIImage?]?
    var voiceOver: AVAsset?
    // MARK: Archiving paths
    static let DocumentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.URLByAppendingPathComponent("scenes")
    // MARK: Types
    struct PropertyKey {
        static let shotVideos = "shotVideos"
        static let shotImages = "shotImages"
        static let voiceOver = "voiceOver"
    }
    // MARK: Initialization
    init?(shotVideos: [AVAsset?]?, shotImages: [UIImage?]?, voiceOver: AVAsset?) {
        // Initialize stored properties
        self.shotVideos = shotVideos
        self.shotImages = shotImages
        self.voiceOver = voiceOver
        super.init()
        // Initialization should fail if properties are not there.
        if shotImages?.isEmpty == true || shotVideos?.isEmpty == true || voiceOver?.tracks.isEmpty == true {return nil}
        
    }
    
    // MARK: NSCoding
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeObject(self.shotVideos as? AnyObject, forKey: PropertyKey.shotVideos)
        coder.encodeObject(self.shotImages as? AnyObject, forKey: PropertyKey.shotImages)
        coder.encodeObject(self.voiceOver, forKey: PropertyKey.voiceOver)
    }
    
    required convenience init?(coder decoder: NSCoder) {
        let shotVideos = decoder.decodeObjectForKey(PropertyKey.shotVideos) as? [AVAsset]
        let shotImages = decoder.decodeObjectForKey(PropertyKey.shotImages) as? [UIImage]
        let voiceOver = decoder.decodeObjectForKey("voiceOver") as? AVAsset?
        
        self.init(shotVideos: shotVideos, shotImages: shotImages, voiceOver: voiceOver!)
        
    }
    
    
}
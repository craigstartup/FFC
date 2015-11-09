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

class Scene {
    // Scene components
    struct shot {
        var video: AVAsset!
        var image: UIImage!
    }
    var shots: [shot]!
    var voiceOver   : AVAsset!
    
    init() {
        
    }
    
}
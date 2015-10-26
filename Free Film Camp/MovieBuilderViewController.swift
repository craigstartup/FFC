//
//  MovieBuilderViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/5/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import Photos
import AVKit


class MovieBuilderViewController: UIViewController {
    
    @IBOutlet weak var headshot: UIImageView!
    
    var vpVC = AVPlayerViewController()
    var previewQueue = [AVPlayerItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    
    @IBAction func addHeadshot(sender: AnyObject) {
    }

    @IBAction func addMusic(sender: AnyObject) {
    }
    
    @IBAction func makeMovie(sender: AnyObject) {
        
        MediaController.sharedMediaController.saveMovie()
    }
    
    @IBAction func preview(sender: AnyObject) {
        
        if MediaController.sharedMediaController.s1Preview != nil &&
        MediaController.sharedMediaController.s2Preview != nil &&
        MediaController.sharedMediaController.s3Preview != nil {
            
            var preview1: AVPlayerItem!, preview2: AVPlayerItem!, preview3: AVPlayerItem!
            preview1 = MediaController.sharedMediaController.s1Preview
            preview2 = MediaController.sharedMediaController.s2Preview
            preview3 = MediaController.sharedMediaController.s3Preview
            
            self.previewQueue = [preview1, preview2, preview3]
            var videoPlayer = AVQueuePlayer()
            videoPlayer.removeAllItems()
            videoPlayer = AVQueuePlayer(items: previewQueue)
            self.vpVC.player = videoPlayer
            self.presentViewController(self.vpVC, animated: true, completion: nil)
        }
    }
    
   
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

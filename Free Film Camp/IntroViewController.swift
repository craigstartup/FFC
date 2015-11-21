//
//  IntroViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 11/19/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class IntroViewController: UIViewController {
    // MARK: Outlets
    @IBOutlet weak var introButton: UIButton!
    @IBOutlet weak var destroyIntroButton: UIButton!
    
    var intro: Intro!
    
    // MARK: View lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
    
    }
    
    
    override func viewWillAppear(animated: Bool) {
        if MediaController.sharedMediaController.intro != nil {
            self.intro = MediaController.sharedMediaController.intro
        }
        
        if self.intro != nil {
            let video = AVURLAsset(URL: intro.video!)
            if self.intro.image == nil {
                let imageMaker = AVAssetImageGenerator(asset: video)
                imageMaker.appliesPreferredTrackTransform = true
                let imageTime = CMTimeMakeWithSeconds(0, 30)
                imageMaker.generateCGImagesAsynchronouslyForTimes([NSValue(CMTime: imageTime)], completionHandler: { (requestedTime, image, actualTime, result, error) -> Void in
                    if result != AVAssetImageGeneratorResult.Succeeded {
                        "Image failure"
                    }
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.introButton.setImage(UIImage(CGImage: image!), forState: .Normal)
                        self.intro.image = UIImage(CGImage: image!)
                    })
                })
            } else {
                self.introButton.setImage(self.intro.image, forState: .Normal)
            }
        }
    }
    
    
    // MARK: Actions
    @IBAction func selectIntro(sender: UIButton) {
        
        
    }
    
    
    @IBAction func destroyIntro(sender: UIButton) {
        
        
    }
    
    
    @IBAction func previewIntro(sender: UIButton) {
        // TODO: Use Media CONTROLLER for preview
        if self.intro != nil {
            let vpVC = AVPlayerViewController()
            let video = AVURLAsset(URL: self.intro.video)
            let preview = AVPlayerItem(asset: video)
            let videoPlayer = AVPlayer(playerItem: preview)
            vpVC.player = videoPlayer
            vpVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
            self.view.window?.rootViewController?.presentViewController(vpVC, animated: true, completion: nil)
        }
    }
    
    // MARK: Segue Methods
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "pickingIntroShot" {
            let destinationVC = segue.destinationViewController as! CameraViewController
            destinationVC.pickingShot = true
            destinationVC.segueToPerform = "introUnwind"
        }
    }
    
    
    @IBAction func introUnwind(unwindSegue: UIStoryboardSegue) {
        self.viewWillAppear(false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

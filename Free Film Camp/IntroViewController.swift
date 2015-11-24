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
        self.intro = MediaController.sharedMediaController.intro
        // Load or initialize intro
        if self.intro == nil {
            guard let loadedIntro = MediaController.sharedMediaController.loadIntro()
                else {
                    print("No intro!")
                    return
                }
            self.intro = loadedIntro
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        // TODO: Clean up logic.
        if self.intro == nil {
            self.destroyIntroButton.alpha = 0
            self.destroyIntroButton.enabled = false
        } else {
            self.destroyIntroButton.alpha = 1
            self.destroyIntroButton.enabled = true
            self.introButton.setImage(self.intro.image, forState: .Normal)
            let video = AVURLAsset(URL: self.getIntroPath())
            print(intro.video)
            
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
            }
        }
    }
    
    
    // MARK: Actions
    @IBAction func selectIntro(sender: UIButton) {
        
        
    }
    
    
    @IBAction func destroyIntro(sender: UIButton) {
        MediaController.sharedMediaController.intro = nil
        self.intro = nil
        do {
            try NSFileManager.defaultManager().removeItemAtPath(Intro.ArchiveURL.path!)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        self.introButton.contentMode = .ScaleAspectFit
        self.introButton.contentVerticalAlignment = .Center
        self.introButton.setImage(UIImage(named: "plus_white_69"), forState: UIControlState.Normal)
        self.destroyIntroButton.alpha = 0
        self.destroyIntroButton.enabled = false
    }
    
    
    @IBAction func previewIntro(sender: UIButton) {
        // TODO: Use Media CONTROLLER for preview
        if self.intro != nil {
            let vpVC = AVPlayerViewController()
            let video = AVURLAsset(URL: self.getIntroPath())
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
    
    // MARK: Helper methods
    func getIntroPath() -> NSURL {
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let filename = "intro.mov"
        let pathArray = [dirPath, filename]
        let url = NSURL.fileURLWithPathComponents(pathArray)!
        MediaController.sharedMediaController.tempPaths.append(url)
        return url
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

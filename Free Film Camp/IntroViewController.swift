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
    @IBOutlet weak var introBoxLabel: UILabel!
    @IBOutlet weak var introLabel: UIButton!
    @IBOutlet weak var introButton: UIButton!
    @IBOutlet weak var destroyIntroButton: UIButton!
    
    var intro: Intro!
    var index: Int!
    
    // MARK: View lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getIntro()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.setButtons()
    }
    
    func getIntro() {
        // Load or initialize intro
        if self.intro == nil {
            guard let loadedIntro = MediaController.sharedMediaController.loadIntro()
                else {
                    print("No intro!")
                    return
            }
            MediaController.sharedMediaController.intro = loadedIntro
            self.intro = MediaController.sharedMediaController.intro
        }
    }
    
    func setButtons() {
        // TODO: Clean up logic.
        if self.intro == nil {
            self.introButton.layer.borderWidth = 2
            self.introButton.layer.borderColor = UIColor.grayColor().CGColor
            self.introBoxLabel.text = "Intro"
            self.introLabel.highlighted = false
        } else {
            self.introBoxLabel.text = ""
            self.introLabel.highlighted = true
            self.introButton.setImage(self.intro.image, forState: .Normal)
            let video = AVURLAsset(URL: MediaController.sharedMediaController.getPathForFileInDocumentsDirectory(self.intro.video))
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
                        MediaController.sharedMediaController.intro.image = UIImage(CGImage: image!)
                    })
                })
            }
        }
    }
    
    // MARK: Actions
    @IBAction func selectIntro(sender: UIButton) {
       self.intro = nil
        MediaController.sharedMediaController.intro = nil
    }
    
    
    @IBAction func destroyIntro(sender: UIButton) {
        MediaController.sharedMediaController.intro = nil
        self.intro = nil
        do {
            try NSFileManager.defaultManager().removeItemAtPath(MediaController.sharedMediaController.getIntroArchivePathURL().path!)
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        self.introButton.contentMode = .ScaleAspectFit
        self.introButton.contentVerticalAlignment = .Center
        self.introButton.setImage(UIImage(named: "Add-Shot-Icon@"), forState: UIControlState.Normal)
        self.destroyIntroButton.alpha = 0
        self.destroyIntroButton.enabled = false
        self.introButton.enabled = true
    }
    
    
    @IBAction func previewIntro(sender: UIButton) {
        // TODO: Use Media CONTROLLER for preview
        if self.intro != nil {
            let vpVC = AVPlayerViewController()
            let video = AVURLAsset(URL: MediaController.sharedMediaController.getIntroShotSavePath())
            let preview = AVPlayerItem(asset: video)
            let videoPlayer = AVPlayer(playerItem: preview)
            vpVC.player = videoPlayer
            vpVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
            
            guard let navigationController = self.view.window?.rootViewController as? UINavigationController else {return}
            guard let topViewController = navigationController.viewControllers.first else {return}
            
            print(topViewController)
            
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
        self.setButtons()
    }
}

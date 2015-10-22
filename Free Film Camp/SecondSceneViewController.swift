//
//  SecondSceneViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/12/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import Photos
import AVFoundation


class SecondSceneViewController: UIViewController {
    
    @IBOutlet weak var shot1Button: UIButton!
    @IBOutlet weak var shot2Button: UIButton!
    @IBOutlet weak var shot3Button: UIButton!
    @IBOutlet weak var recordVoiceOverButton: UIButton!
    @IBOutlet weak var recordVoiceOverLabel: UILabel!
    
    
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    let fetchOptions = PHFetchOptions()
    let toAlbumTitle = "Free Film Camp Scenes"
    let audioID = "s2AudioSelectedSegue"
    let clipID = "s2ClipSelectedSegue"
    
    var assetRequestNumber: Int!
    var scene = 2
    var buttonToChange: UIButton!
    
    var selectedVideoAsset: NSURL!
    var selectedVideoImage: UIImage!
    var audioAsset: AVAsset!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        if assetRequestNumber != nil {
            
            if self.assetRequestNumber == 1 {
                
                MediaController.sharedMediaController.s2Shot1Image = self.selectedVideoImage
                
            } else if self.assetRequestNumber == 2 {
                
                MediaController.sharedMediaController.s2Shot2Image = self.selectedVideoImage
                
                
            } else if self.assetRequestNumber == 3 {
                
                MediaController.sharedMediaController.s2Shot3Image = self.selectedVideoImage
                
            }
        }
        
        if MediaController.sharedMediaController.s2Shot1Image != nil {
            self.shot1Button.setImage(MediaController.sharedMediaController.s2Shot1Image, forState: UIControlState.Normal)
            self.shot1Button.imageView!.contentMode = UIViewContentMode.ScaleToFill
            self.shot1Button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
            self.shot1Button.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
        }
        
        if MediaController.sharedMediaController.s2Shot2Image != nil {
            self.shot2Button.setImage(MediaController.sharedMediaController.s2Shot2Image, forState: UIControlState.Normal)
            self.shot2Button.imageView!.contentMode = UIViewContentMode.ScaleToFill
            self.shot2Button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
            self.shot2Button.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
        }
        
        if MediaController.sharedMediaController.s2Shot3Image != nil {
            self.shot3Button.setImage(MediaController.sharedMediaController.s2Shot3Image, forState: UIControlState.Normal)
            self.shot3Button.imageView!.contentMode = UIViewContentMode.ScaleToFill
            self.shot3Button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
            self.shot3Button.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
        }
        
        if MediaController.sharedMediaController.s2VoiceOver != nil {
            
            let check = UIImage(named: "Check")
            self.recordVoiceOverButton.setImage(check, forState: UIControlState.Normal)
        }

    }
    
    @IBAction func selectClipOne(sender: AnyObject) {
        
        self.assetRequestNumber = 1
        self.performSegueWithIdentifier("s2SelectClip", sender: self)
        
    }
    
    @IBAction func selectClipTwo(sender: AnyObject) {
        
        self.assetRequestNumber = 2
        self.performSegueWithIdentifier("s2SelectClip", sender: self)
    }
    
    @IBAction func selectClip3(sender: AnyObject) {
        
        self.assetRequestNumber = 3
        self.performSegueWithIdentifier("s2SelectClip", sender: self)
    }
    
    @IBAction func record(sender: AnyObject) {
        
    }
    
    @IBAction func previewSelection(sender: AnyObject) {
    }
    
    @IBAction func mergeMedia(sender: AnyObject) {
        
        MediaController.sharedMediaController.saveScene(self.scene)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "s2SelectClip" {
            
            let destinationVC = segue.destinationViewController as! VideosViewController
            destinationVC.segueID = self.clipID
        } else if segue.identifier == "s2SelectAudio" {
            
            let destinationVC = segue.destinationViewController as! VoiceOverViewController
            destinationVC.segueID = self.audioID
        }
    }
    // MARK: unwind segues
    @IBAction func s2ClipUnwindSegue(unwindSegue: UIStoryboardSegue) {
        
        if assetRequestNumber == 1 {
            
            MediaController.sharedMediaController.s2Shot1 = AVAsset(URL: self.selectedVideoAsset)
        } else if assetRequestNumber == 2 {
            
            MediaController.sharedMediaController.s2Shot2 = AVAsset(URL: self.selectedVideoAsset)
        } else if assetRequestNumber == 3 {
            
            MediaController.sharedMediaController.s2Shot3 = AVAsset(URL: self.selectedVideoAsset)
        }
    }
    
    @IBAction func s2AudioUnwindSegue(unwindSegue: UIStoryboardSegue){
        
        MediaController.sharedMediaController.s2VoiceOver = self.audioAsset
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

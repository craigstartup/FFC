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
    
    
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    let fetchOptions = PHFetchOptions()
    let toAlbumTitle = "Free Film Camp Scenes"
    let audioID = "s2AudioSelectedSegue"
    let clipID = "s2ClipSelectedSegue"
    
    var assetRequestNumber: Int!
    var scene = 2
    
    var selectedVideoAsset: NSURL!
    var audioAsset: AVAsset!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
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

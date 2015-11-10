//  Assisted by http://www.raywenderlich.com/94404/play-record-merge-videos-ios-swift
//  SceneBuilderViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/5/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import AVKit

class FirstSceneViewController: UIViewController {

    @IBOutlet weak var savingProgress: UIActivityIndicatorView!
    @IBOutlet weak var shot1Button: UIButton!
    @IBOutlet weak var shot2Button: UIButton!
    @IBOutlet weak var shot3Button: UIButton!
    @IBOutlet var removeMediaButtons: Array<UIButton>!
    @IBOutlet weak var recordVoiceOverButton: UIButton!
    @IBOutlet weak var voiceOverLabel: UILabel!
    
    var vpVC = AVPlayerViewController()
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    
    var videoPlayer: AVPlayer!
    
    let clipID = "s1ClipSelectedSegue"
    let audioID = "s1AudioSelectedSegue"
    var assetRequestNumber: Int!
    var scene = 1
    
    var selectedVideoAsset: NSURL!
    var selectedVideoImage: UIImage!
    var audioAsset: AVAsset!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for button in removeMediaButtons {
            button.alpha = 0
            button.enabled = false
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        defer {
            self.assetRequestNumber = nil
            self.selectedVideoImage = nil
        }
        self.navigationController?.navigationBarHidden = true
        self.navigationController?.navigationBar.translucent = true
        
        if assetRequestNumber != nil {
            if self.assetRequestNumber == 1 {
                MediaController.sharedMediaController.s1Shot1Image = self.selectedVideoImage
            } else if self.assetRequestNumber == 2 {
                MediaController.sharedMediaController.s1Shot2Image = self.selectedVideoImage
            } else if self.assetRequestNumber == 3 {
                MediaController.sharedMediaController.s1Shot3Image = self.selectedVideoImage
            }
        }
        
        if MediaController.sharedMediaController.s1Shot1Image != nil &&
        MediaController.sharedMediaController.s1Shot1 != nil {
            self.shot1Button.setImage(MediaController.sharedMediaController.s1Shot1Image, forState: UIControlState.Normal)
            self.shot1Button.imageView!.contentMode = UIViewContentMode.ScaleToFill
            self.shot1Button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
            self.shot1Button.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
            self.removeMediaButtons[0].alpha = 1
            self.removeMediaButtons[0].enabled = true
        }
        
        if MediaController.sharedMediaController.s1Shot2Image != nil &&
        MediaController.sharedMediaController.s1Shot2 != nil {
            self.shot2Button.setImage(MediaController.sharedMediaController.s1Shot2Image, forState: UIControlState.Normal)
            self.shot2Button.imageView!.contentMode = UIViewContentMode.ScaleToFill
            self.shot2Button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
            self.shot2Button.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
            self.removeMediaButtons[1].alpha = 1
            self.removeMediaButtons[1].enabled = true
        }
        
        if MediaController.sharedMediaController.s1Shot3Image != nil &&
        MediaController.sharedMediaController.s1Shot3 != nil {
            self.shot3Button.setImage(MediaController.sharedMediaController.s1Shot3Image, forState: UIControlState.Normal)
            self.shot3Button.imageView!.contentMode = UIViewContentMode.ScaleToFill
            self.shot3Button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
            self.shot3Button.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
            self.removeMediaButtons[2].alpha = 1
            self.removeMediaButtons[2].enabled = true
        }
        
        if MediaController.sharedMediaController.s1VoiceOver != nil {
            let check = UIImage(named: "Check")
            self.recordVoiceOverButton.setImage(check, forState: UIControlState.Normal)
            self.removeMediaButtons[3].alpha = 1
            self.removeMediaButtons[3].enabled = true
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        self.videoPlayer = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    @IBAction func selectClipOne(sender: AnyObject) {
        MediaController.sharedMediaController.s1Shot1 = nil
        self.selectedVideoAsset = nil
        self.assetRequestNumber = 1
        self.removeMediaButtons[0].alpha = 1
        self.removeMediaButtons[0].enabled = true
        self.performSegueWithIdentifier("s1SelectClip", sender: self)
    }
    
    @IBAction func selectClipTwo(sender: AnyObject) {
        MediaController.sharedMediaController.s1Shot2 = nil
        self.selectedVideoAsset = nil
        self.assetRequestNumber = 2
        self.removeMediaButtons[1].alpha = 1
        self.removeMediaButtons[1].enabled = true
        self.performSegueWithIdentifier("s1SelectClip", sender: self)
    }
    
    @IBAction func selectClip3(sender: AnyObject) {
        MediaController.sharedMediaController.s1Shot3 = nil
        self.selectedVideoAsset = nil
        self.assetRequestNumber = 3
        self.removeMediaButtons[2].alpha = 1
        self.removeMediaButtons[2].enabled = true
        self.performSegueWithIdentifier("s1SelectClip", sender: self)
    }
    
    @IBAction func recordVoiceOver(sender: AnyObject) {
        MediaController.sharedMediaController.s1VoiceOver = nil
        self.audioAsset = nil
        self.removeMediaButtons[3].alpha = 1
        self.removeMediaButtons[3].enabled = true
    }
    
    
    @IBAction func removeMedia(sender: AnyObject) {
        
        switch(sender.tag) {
        case 1:
            MediaController.sharedMediaController.s1Shot1Image = nil
            MediaController.sharedMediaController.s1Shot1 = nil
            self.removeMediaButtons[sender.tag - 1].alpha = 0
            self.shot1Button.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
            self.shot1Button.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            self.shot1Button.setImage(UIImage(named: "plus_white_69"), forState: UIControlState.Normal)
            break
        case 2:
            MediaController.sharedMediaController.s1Shot2Image = nil
            MediaController.sharedMediaController.s1Shot2 = nil
            self.removeMediaButtons[sender.tag - 1].alpha = 0
            self.shot2Button.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
            self.shot2Button.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            self.shot2Button.setImage(UIImage(named: "plus_white_69"), forState: UIControlState.Normal)
            break
        case 3:
            MediaController.sharedMediaController.s1Shot3Image = nil
            MediaController.sharedMediaController.s1Shot3 = nil
            self.removeMediaButtons[sender.tag - 1].alpha = 0
            self.shot3Button.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
            self.shot3Button.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            self.shot3Button.setImage(UIImage(named: "plus_white_69"), forState: UIControlState.Normal)
            break
        case 4:
            MediaController.sharedMediaController.s1VoiceOver = nil
            self.removeMediaButtons[sender.tag - 1].alpha = 0
            self.recordVoiceOverButton.imageView!.image = nil
            self.recordVoiceOverButton.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
            self.recordVoiceOverButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            self.recordVoiceOverButton.setImage(UIImage(named: "plus_white_69"), forState: UIControlState.Normal)
            break
        default:
            print("DEFAULT!")
        }
    }
    
    @IBAction func previewSelection(sender: AnyObject) {
        var firstAsset: AVAsset!, secondAsset: AVAsset!, thirdAsset: AVAsset!, voiceOverAsset: AVAsset!
                firstAsset = MediaController.sharedMediaController.s1Shot1
                secondAsset = MediaController.sharedMediaController.s1Shot2
                thirdAsset  = MediaController.sharedMediaController.s1Shot3
                voiceOverAsset = MediaController.sharedMediaController.s1VoiceOver
                var timeCursor = kCMTimeZero
        
            if firstAsset != nil && secondAsset != nil && thirdAsset != nil {
                let assets = [firstAsset, secondAsset, thirdAsset]
                var tracks = [AVMutableCompositionTrack]()
                let mediaToPreview = AVMutableComposition()
                
                
                for item in assets {
                    let videoTrack: AVMutableCompositionTrack = mediaToPreview.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
                    do {
                        try videoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, item.duration), ofTrack: item.tracksWithMediaType(AVMediaTypeVideo)[0],
                            atTime: timeCursor)
                        
                    } catch let audioTrackError as NSError{
                        print(audioTrackError.localizedDescription)
                    }
                    timeCursor = CMTimeAdd(timeCursor, item.duration)
                    tracks.append(videoTrack)
                }
                
                let mainInstruction = AVMutableVideoCompositionInstruction()
                mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, timeCursor)
                
                var instructions = [AVMutableVideoCompositionLayerInstruction]()
                var instructionTime: CMTime = kCMTimeZero
                // Create seperate instructions for each track.
                for var i = 0; i < tracks.count; i++ {
                    let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: tracks[i])
                    instructionTime = CMTimeAdd(instructionTime, assets[i].duration)
                    instruction.setOpacity(0.0, atTime: instructionTime)
                    instructions.append(instruction)
                }
                
                // Add individual instructions to main for execution.
                mainInstruction.layerInstructions = instructions
                let mainComposition = AVMutableVideoComposition()
                // Add instruction composition to main composition and set frame rate to 30 per second.
                mainComposition.instructions = [mainInstruction]
                mainComposition.frameDuration = CMTimeMake(1, 30)
                mainComposition.renderSize = mediaToPreview.naturalSize
                if voiceOverAsset != nil {
                    let voiceOverTrack: AVMutableCompositionTrack = mediaToPreview.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
                    
                    do {
                        try voiceOverTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, timeCursor), ofTrack: voiceOverAsset.tracksWithMediaType(AVMediaTypeAudio)[0] ,
                            atTime: kCMTimeZero)
                        
                    } catch let audioTrackError as NSError{
                        print(audioTrackError.localizedDescription)
                    }
                }
                let itemToPreview = AVPlayerItem(asset: mediaToPreview)
                itemToPreview.videoComposition = mainComposition
                self.videoPlayer = AVPlayer(playerItem: itemToPreview)
                self.vpVC.player = videoPlayer
                vpVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
                presentViewController(vpVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func mergeMedia(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveCompleted:", name: MediaController.Notifications.saveSceneFinished, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveFailed:", name: MediaController.Notifications.saveSceneFailed, object: nil)
        self.savingProgress.alpha = 1
        self.savingProgress.startAnimating()
        self.view.alpha = 0.6
        MediaController.sharedMediaController.saveScene(scene)
    }
    // MARK: save notifications
    func saveCompleted(notification: NSNotification) {
        self.savingProgress.stopAnimating()
        self.savingProgress.alpha = 0
        self.view.alpha = 1
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.saveSceneFinished, object: nil)
        let alertSuccess = UIAlertController(title: "Success", message: "Scene saved to Photos!", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Thanks!", style: .Default) { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alertSuccess.addAction(okAction)
        self.presentViewController(alertSuccess, animated: true, completion: nil)
    }
    
    func saveFailed(notification: NSNotification) {
        self.savingProgress.stopAnimating()
        self.savingProgress.alpha = 0
        self.view.alpha = 1
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.saveSceneFailed, object: nil)
        let alertFailure = UIAlertController(title: "Failure", message: "Scene failed to save. Re-select media and try again", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Thanks!", style: .Default) { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alertFailure.addAction(okAction)
        self.presentViewController(alertFailure, animated: true, completion: nil)
    }
    // MARK: segue methods
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "s1SelectClip" {
            let destinationVC = segue.destinationViewController as! VideosViewController
            destinationVC.segueID = self.clipID
            destinationVC.shotNumber = self.assetRequestNumber
        } else if segue.identifier == "s1SelectAudio" {
            let destinationVC = segue.destinationViewController as! VoiceOverViewController
            destinationVC.segueID = self.audioID
        }
    }
    
    @IBAction func s1ClipUnwindSegue(unwindSegue: UIStoryboardSegue) {
        defer {
            self.selectedVideoAsset = nil
        }
        if self.selectedVideoAsset != nil {
            if assetRequestNumber == 1 {
                MediaController.sharedMediaController.s1Shot1 = AVAsset(URL: self.selectedVideoAsset)
            } else if assetRequestNumber == 2 {
                MediaController.sharedMediaController.s1Shot2 = AVAsset(URL: self.selectedVideoAsset)
            } else if assetRequestNumber == 3 {
                MediaController.sharedMediaController.s1Shot3 = AVAsset(URL: self.selectedVideoAsset)
            }
        }
    }
    
    @IBAction func s1AudioUnwindSegue(unwindSegue: UIStoryboardSegue){
        if self.audioAsset != nil {
            MediaController.sharedMediaController.s1VoiceOver = self.audioAsset
            self.audioAsset = nil
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

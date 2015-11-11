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
    @IBOutlet var shotButtons: Array<UIButton>!
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
        
        MediaController.sharedMediaController.scene1 = Scene(shotVideos: [nil,nil,nil], shotImages: [nil,nil,nil], voiceOver: nil)
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
                MediaController.sharedMediaController.scene1.shotImages![0] = self.selectedVideoImage
            } else if self.assetRequestNumber == 2 {
                MediaController.sharedMediaController.scene1.shotImages![1] = self.selectedVideoImage
            } else if self.assetRequestNumber == 3 {
                MediaController.sharedMediaController.scene1.shotImages![2] = self.selectedVideoImage
            }
        }
        
        for var i = 0; i < self.shotButtons.count; i++ {
            let images = MediaController.sharedMediaController.scene1.shotImages
            let videos = MediaController.sharedMediaController.scene1.shotVideos
            if images![i] != nil && videos![i] != nil {
                self.shotButtons[i].setImage(images![i], forState: UIControlState.Normal)
                self.shotButtons[i].imageView!.contentMode = UIViewContentMode.ScaleToFill
                self.shotButtons[i].contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
                self.shotButtons[i].contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
                self.removeMediaButtons[i].alpha = 1
                self.removeMediaButtons[i].enabled = true
            }
        }
        
        if MediaController.sharedMediaController.scene1.voiceOver != nil {
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
    
    @IBAction func selectClip(sender: UIButton) {
        self.selectedVideoAsset = nil
        self.assetRequestNumber = sender.tag
        self.removeMediaButtons[sender.tag - 1].alpha = 1
        self.removeMediaButtons[sender.tag - 1].enabled = true
        self.performSegueWithIdentifier("s1SelectClip", sender: self)
    }
    
    @IBAction func removeMedia(sender: AnyObject) {
        MediaController.sharedMediaController.scene1.shotVideos![sender.tag - 1] = nil
        self.removeMediaButtons[sender.tag - 1].alpha = 0
        self.shotButtons[sender.tag - 1].contentVerticalAlignment = UIControlContentVerticalAlignment.Center
        self.shotButtons[sender.tag - 1].imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        self.shotButtons[sender.tag - 1].setImage(UIImage(named: "plus_white_69"), forState: UIControlState.Normal)
    }
    
    @IBAction func previewSelection(sender: AnyObject) {
        var firstAsset: AVAsset!, secondAsset: AVAsset!, thirdAsset: AVAsset!, voiceOverAsset: AVAsset!
        firstAsset = MediaController.sharedMediaController.scene1.shotVideos![0]
        secondAsset = MediaController.sharedMediaController.scene1.shotVideos![1]
        thirdAsset  = MediaController.sharedMediaController.scene1.shotVideos![2]
        audioAsset? = MediaController.sharedMediaController.scene1.voiceOver!
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
            MediaController.sharedMediaController.scene1.shotVideos![assetRequestNumber - 1] = AVAsset(URL: self.selectedVideoAsset)
        }
    }
    
    @IBAction func s1AudioUnwindSegue(unwindSegue: UIStoryboardSegue){
        if self.audioAsset != nil {
            MediaController.sharedMediaController.scene1.voiceOver = self.audioAsset
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

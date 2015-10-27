//
//  ThirdSceneViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/12/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import Photos
import AVFoundation
import AVKit

class ThirdSceneViewController: UIViewController {
    
    @IBOutlet weak var savingProgress: UIActivityIndicatorView!
    @IBOutlet weak var shot1Button: UIButton!
    @IBOutlet weak var shot2Button: UIButton!
    @IBOutlet weak var shot3Button: UIButton!
    @IBOutlet weak var recordVoiceOverButton: UIButton!
    @IBOutlet weak var recordVoiceOverLabel: UILabel!
    
    var vpVC = AVPlayerViewController()
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    let fetchOptions = PHFetchOptions()
    var assetRequestNumber: Int!
    let clipID = "s3ClipSelectedSegue"
    let audioID = "s3AudioSelectedSegue"
    var scene = 3
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
                
                MediaController.sharedMediaController.s3Shot1Image = self.selectedVideoImage
                
            } else if self.assetRequestNumber == 2 {
                
                MediaController.sharedMediaController.s3Shot2Image = self.selectedVideoImage
                
                
            } else if self.assetRequestNumber == 3 {
                
                MediaController.sharedMediaController.s3Shot3Image = self.selectedVideoImage
                
            }
        }
        
        if MediaController.sharedMediaController.s3Shot1Image != nil {
            self.shot1Button.setImage(MediaController.sharedMediaController.s3Shot1Image, forState: UIControlState.Normal)
            self.shot1Button.imageView!.contentMode = UIViewContentMode.ScaleToFill
            self.shot1Button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
            self.shot1Button.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
        }
        
        if MediaController.sharedMediaController.s3Shot2Image != nil {
            self.shot2Button.setImage(MediaController.sharedMediaController.s3Shot2Image, forState: UIControlState.Normal)
            self.shot2Button.imageView!.contentMode = UIViewContentMode.ScaleToFill
            self.shot2Button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
            self.shot2Button.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
        }
        
        if MediaController.sharedMediaController.s3Shot3Image != nil {
            self.shot3Button.setImage(MediaController.sharedMediaController.s3Shot3Image, forState: UIControlState.Normal)
            self.shot3Button.imageView!.contentMode = UIViewContentMode.ScaleToFill
            self.shot3Button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Fill
            self.shot3Button.contentVerticalAlignment = UIControlContentVerticalAlignment.Fill
        }
        
        if MediaController.sharedMediaController.s3VoiceOver != nil {
            
            let check = UIImage(named: "Check")
            self.recordVoiceOverButton.setImage(check, forState: UIControlState.Normal)
        }

    }
    
    @IBAction func selectClipOne(sender: AnyObject) {
        
        self.assetRequestNumber = 1
        self.performSegueWithIdentifier("s3SelectClip", sender: self)
        
    }
    
    @IBAction func selectClipTwo(sender: AnyObject) {
        
        self.assetRequestNumber = 2
        self.performSegueWithIdentifier("s3SelectClip", sender: self)
    }
    
    @IBAction func selectClip3(sender: AnyObject) {
        
        self.assetRequestNumber = 3
        self.performSegueWithIdentifier("s3SelectClip", sender: self)
    }
    
    @IBAction func record(sender: AnyObject) {
    }
    
    @IBAction func previewSelection(sender: AnyObject) {
        
        var firstAsset: AVAsset!, secondAsset: AVAsset!, thirdAsset: AVAsset!, voiceOverAsset: AVAsset!
        
        firstAsset = MediaController.sharedMediaController.s3Shot1
        secondAsset = MediaController.sharedMediaController.s3Shot2
        thirdAsset  = MediaController.sharedMediaController.s3Shot3
        voiceOverAsset = MediaController.sharedMediaController.s3VoiceOver
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
            MediaController.sharedMediaController.s3Preview = itemToPreview
            let videoPlayer = AVPlayer(playerItem: itemToPreview)
            self.vpVC.player = videoPlayer
            self.presentViewController(self.vpVC, animated: true, completion: nil)
        }

    }
    
    @IBAction func mergeMedia(sender: AnyObject) {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveCompleted:", name: "saveComplete", object: nil)
        self.savingProgress.alpha = 1
        self.savingProgress.startAnimating()
        self.view.alpha = 0.7
        MediaController.sharedMediaController.saveScene(scene)
    }
    
    func saveCompleted(notification: NSNotification) {
        
        self.savingProgress.stopAnimating()
        self.savingProgress.alpha = 0
        self.view.alpha = 1
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "s3SelectClip" {
            
            let destinationVC = segue.destinationViewController as! VideosViewController
            destinationVC.segueID = self.clipID
        } else if segue.identifier == "s3SelectAudio" {
            
            let destinationVC = segue.destinationViewController as! VoiceOverViewController
            destinationVC.segueID = self.audioID
        }
    }
    
    // MARK: unwind segues
    @IBAction func s3ClipUnwindSegue(unwindSegue: UIStoryboardSegue) {
        
        if assetRequestNumber == 1 {
            
            MediaController.sharedMediaController.s3Shot1 = AVAsset(URL: self.selectedVideoAsset)
        } else if assetRequestNumber == 2 {
            
            MediaController.sharedMediaController.s3Shot2 = AVAsset(URL: self.selectedVideoAsset)
        } else if assetRequestNumber == 3 {
            
            MediaController.sharedMediaController.s3Shot3 = AVAsset(URL: self.selectedVideoAsset)
        }
    }
    
    @IBAction func s3AudioUnwindSegue(unwindSegue: UIStoryboardSegue){
        
        MediaController.sharedMediaController.s3VoiceOver = self.audioAsset
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

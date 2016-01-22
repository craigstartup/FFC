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
import SwiftyDropbox

class SceneViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var sceneLabel: UIButton!
    @IBOutlet var sceneAddMediaButtons: Array<UIButton>!
    @IBOutlet var shotLabels: Array<UILabel>!
    
    var sceneButtons              = [[UIButton]?]()

    //Button types
    let ADD_BUTTONS               = 0
    let SHOT1                     = 0, SHOT2 = 1, SHOT3 = 2, VOICEOVER = 3

    //let soundwaveView: FVSoundWaveView = FVSoundWaveView()
    var vpVC: AVPlayerViewController!
    let library                   = PHPhotoLibrary.sharedPhotoLibrary()

    // Scene specific identifiers
    var shotSelectedSegueID       = "sceneShotSelectedSegue"
    var voiceOverSelectedSegueID  = "sceneVoiceOverSelectedSegue"
    var selectingShotSegueID      = "sceneSelectingShotSegue"
    var selectingVoiceOverSegueID = "sceneSelectingVoiceOverSegue"
    var sceneNumber:        Int!
    var index: Int!
    var assetRequestNumber: Int!
    var scene: Scene!

    var selectedVideoAsset: NSURL!
    var selectedVideoImage: UIImage!
    var audioAsset: NSURL!
    // placeholder values
    let defaultImage              = UIImage(named: "Add-Shot-Icon@")
    let defaultVideoURL           = NSURL(string: "placeholder")
    let defaultVoiceOverFile      = "placeholder"
    
    // MARK: View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
            for button in self.sceneAddMediaButtons {
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.grayColor().CGColor
        }
        
        self.vpVC = AVPlayerViewController()
    }
    
    
    override func viewWillAppear(animated: Bool) {
        MediaController.sharedMediaController.albumTitle = MediaController.Albums.scenes
        self.scene = MediaController.sharedMediaController.scenes[sceneNumber]
        
        defer {
            self.assetRequestNumber = nil
            self.selectedVideoAsset = nil
            self.selectedVideoImage = nil
        }
        
        self.sceneButtons = [self.sceneAddMediaButtons]
        
        self.navigationController?.navigationBar.translucent = true
        self.setupView()
        self.sceneLabel.setTitle("    Scene \(self.sceneNumber + 1)", forState: .Normal)
        self.sceneLabel.setTitle("    Scene \(self.sceneNumber + 1)", forState: .Highlighted)
    }
    
    func setupView() {
        defer {
            self.selectedVideoAsset = nil
            self.selectedVideoImage = nil
        }
        
        if assetRequestNumber != nil && self.selectedVideoAsset != nil && self.selectedVideoImage != nil {
            self.scene.shotImages[assetRequestNumber - 1] = self.selectedVideoImage
            self.scene.shotVideos[assetRequestNumber - 1] = self.selectedVideoAsset
            MediaController.sharedMediaController.saveScenes()
        }
        
        // Set button images
        for var i = 0; i < self.sceneButtons[ADD_BUTTONS]!.count; i++ {
            let images = self.scene.shotImages
            let videos = self.scene.shotVideos
            
            if images.count > i && videos[i] != self.defaultVideoURL {
                self.sceneButtons[ADD_BUTTONS]![i].setImage(images[i], forState: UIControlState.Normal)
                self.sceneButtons[ADD_BUTTONS]![i].contentMode = UIViewContentMode.ScaleAspectFit
                self.sceneButtons[ADD_BUTTONS]![i].contentVerticalAlignment = UIControlContentVerticalAlignment.Center
            }
        }
        
        // Access stored voiceover.
        let filePath = MediaController.sharedMediaController.getPathForFileInDocumentsDirectory(self.scene.voiceOver)
        
        if NSFileManager.defaultManager().fileExistsAtPath(filePath.path!) {
            MediaController.sharedMediaController.saveScenes()
            self.sceneButtons[ADD_BUTTONS]![VOICEOVER].highlighted = true
            self.sceneButtons[ADD_BUTTONS]![VOICEOVER].setTitle("", forState: .Highlighted)
        } else {
            self.scene.voiceOver = self.defaultVoiceOverFile
            MediaController.sharedMediaController.saveScenes()
        }
        self.checkForCompletedScene()
    }
    
    func checkForCompletedScene() {
        var completedShots = 0
        
        for shot in self.scene.shotVideos {
            if shot != self.defaultVideoURL {
                completedShots += 1
            }
        }
        
        if completedShots == 3 {
            self.sceneLabel.highlighted = true
        } else {
            self.sceneLabel.highlighted = false
        }

    }
    
    // MARK: Button Actions
    @IBAction func selectMedia(sender: UIButton) {
        self.assetRequestNumber = sender.tag
        let buttonPressed = sender.tag - 1
        
        if buttonPressed > SHOT3 {
            NSNotificationCenter.defaultCenter().postNotificationName(MediaController.Notifications.voiceoverCalled, object: self)
        } else {
            self.performSegueWithIdentifier(self.selectingShotSegueID, sender: self)
            self.shotLabels[buttonPressed].alpha = 0
            NSNotificationCenter.defaultCenter().postNotificationName(MediaController.Notifications.selectShotCalled, object: self)
        }
    }
    
    @IBAction func previewSelection(sender: AnyObject) {
        MediaController.sharedMediaController.prepareMediaFor(scene: self.sceneNumber, movie: false, save: false)
        let vpVC = MediaController.sharedMediaController.playerForPreview()
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.presentViewController(vpVC, animated: true, completion: nil)
        })
    }
    
    // MARK: segue methods
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == selectingShotSegueID {
            let destinationVC = segue.destinationViewController as! VideosViewController
            destinationVC.segueID = self.shotSelectedSegueID
            destinationVC.shotNumber = self.assetRequestNumber
        } else if segue.identifier == self.selectingVoiceOverSegueID {
            let destinationVC = segue.destinationViewController as! VoiceOverViewController
            destinationVC.sceneID = self.sceneNumber
            destinationVC.audioSaveID = "scene\(self.sceneNumber)"
        }
    }
    
    
    @IBAction func sceneShotUnwindSegue(unwindSegue: UIStoryboardSegue) {
        self.checkForCompletedScene()
    }
    
    @IBAction func sceneAudioUnwindSegue(unwindSegue: UIStoryboardSegue){
       
    }
}

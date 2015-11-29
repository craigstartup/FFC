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

class SceneViewController: UIViewController {
    // MARK: Properties
    @IBOutlet weak var savingProgress: UIActivityIndicatorView!
    
    @IBOutlet var sceneAddMediaButtons: Array<UIButton>!
    @IBOutlet var sceneRemoveMediaButtons: Array<UIButton>!
    
    var sceneButtons              = [[UIButton]?]()

    //Button types
    let ADD_BUTTONS               = 0
    let DESTROY_BUTTONS           = 1
    let SHOT1                     = 0, SHOT2 = 1, SHOT3 = 2, VOICEOVER = 3

    var vpVC                      = AVPlayerViewController()
    let library                   = PHPhotoLibrary.sharedPhotoLibrary()

    var videoPlayer: AVPlayer!

    // Scene specific identifiers
    var shotSelectedSegueID       = "sceneShotSelectedSegue"
    var voiceOverSelectedSegueID  = "sceneVoiceOverSelectedSegue"
    var selectingShotSegueID      = "sceneSelectingShotSegue"
    var selectingVoiceOverSegueID = "sceneSelectingVoiceOverSegue"
    var sceneNumber:        Int!
    var assetRequestNumber: Int!
    var scene: Scene!

    var selectedVideoAsset: NSURL!
    var selectedVideoImage: UIImage!
    var audioAsset: NSURL!
    // placeholder values
    let defaultImage              = UIImage(named: "plus_white_69")
    let defaultVideoURL           = NSURL(string: "placeholder")
    let defaultVoiceOverFile      = "placeholder"
    // MARK: View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load scenes or initialize if none exist.
        MediaController.sharedMediaController.scenes = MediaController.sharedMediaController.loadScenes()
        if MediaController.sharedMediaController.scenes.isEmpty {
            for _ in 0..<3 {
                let scene = Scene(shotVideos: Array(count: 3, repeatedValue: defaultVideoURL!), shotImages: Array(count: 3, repeatedValue: defaultImage!), voiceOver: defaultVoiceOverFile)
                MediaController.sharedMediaController.scenes.append(scene!)
            }
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        MediaController.sharedMediaController.albumTitle = MediaController.Albums.scenes
        self.scene = MediaController.sharedMediaController.scenes[sceneNumber]
        
        defer {
            self.assetRequestNumber = nil
            self.selectedVideoAsset = nil
            self.selectedVideoImage = nil
        }
        // Access stored voiceover.
        let filePath = MediaController.sharedMediaController.getPathForFileInDocumentsDirectory(self.scene.voiceOver)
        
        if NSFileManager.defaultManager().fileExistsAtPath(filePath.path!) {
            print("VOFILE!!!!!!!!!!!!!!!!")
            MediaController.sharedMediaController.saveScenes()
        } else {
            print("FUCKVO!!!!!!!!!!!\(MediaController.sharedMediaController.scenes[sceneNumber].voiceOver)")
            self.scene.voiceOver = self.defaultVoiceOverFile
            MediaController.sharedMediaController.saveScenes()
        }
        
        
        self.sceneButtons = [self.sceneAddMediaButtons, self.sceneRemoveMediaButtons]
        
        for button in self.sceneButtons[DESTROY_BUTTONS]! {
            button.alpha   = 0
            button.enabled = false
        }
        
        self.navigationController?.navigationBarHidden = true
        
        if assetRequestNumber != nil && self.selectedVideoAsset != nil && self.selectedVideoImage != nil {
            self.scene.shotImages[assetRequestNumber - 1] = self.selectedVideoImage
            self.scene.shotVideos[assetRequestNumber - 1] = self.selectedVideoAsset
            MediaController.sharedMediaController.saveScenes()
        }
        
        // Set button images
        for var i = 0; i < self.sceneButtons[ADD_BUTTONS]!.count ; i++ {
            let images = self.scene.shotImages
            let videos = self.scene.shotVideos
            if images.count > i && videos[i] != self.defaultVideoURL {
                self.sceneButtons[ADD_BUTTONS]![i].setImage(images[i], forState: UIControlState.Normal)
                self.sceneButtons[ADD_BUTTONS]![i].contentMode = UIViewContentMode.ScaleAspectFit
                self.sceneButtons[ADD_BUTTONS]![i].contentVerticalAlignment = UIControlContentVerticalAlignment.Center
                if self.sceneButtons[ADD_BUTTONS]![i].currentImage != defaultImage {
                    self.sceneButtons[DESTROY_BUTTONS]![i].alpha = 1
                    self.sceneButtons[DESTROY_BUTTONS]![i].enabled = true
                }
            }
        }
        
        if self.scene.voiceOver != defaultVoiceOverFile {
            let check = UIImage(named: "Check")
            self.sceneButtons[ADD_BUTTONS]![VOICEOVER].setImage(check, forState: UIControlState.Normal)
            self.sceneButtons[DESTROY_BUTTONS]![VOICEOVER].alpha = 1
            self.sceneButtons[DESTROY_BUTTONS]![VOICEOVER].enabled = true
        }
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        self.videoPlayer = nil
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: Button Actions
    @IBAction func selectMedia(sender: UIButton) {
        self.assetRequestNumber = sender.tag
        let buttonPressed = sender.tag - 1
        
        self.sceneButtons[DESTROY_BUTTONS]![buttonPressed].alpha = 1
        self.sceneButtons[DESTROY_BUTTONS]![buttonPressed].enabled = true
        
        if buttonPressed > SHOT3 {
            self.audioAsset = nil
        } else {
            self.selectedVideoAsset = nil
            self.performSegueWithIdentifier(self.selectingShotSegueID, sender: self)
        }
    }
    
    
    @IBAction func removeMedia(sender: AnyObject) {
        if sender.tag < 4 {
            self.scene.shotVideos[sender.tag - 1] = self.defaultVideoURL!
            self.scene.shotImages[sender.tag - 1] = self.defaultImage!
            self.sceneButtons[ADD_BUTTONS]![sender.tag - 1].contentVerticalAlignment = UIControlContentVerticalAlignment.Center
            self.sceneButtons[ADD_BUTTONS]![sender.tag - 1].imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            self.sceneButtons[ADD_BUTTONS]![sender.tag - 1].setImage(self.scene.shotImages[sender.tag - 1], forState: UIControlState.Normal)
        } else if sender.tag == 4 {
            self.sceneButtons[ADD_BUTTONS]![VOICEOVER].contentVerticalAlignment = UIControlContentVerticalAlignment.Center
            self.sceneButtons[ADD_BUTTONS]![VOICEOVER].imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            self.sceneButtons[ADD_BUTTONS]![VOICEOVER].setImage(self.defaultImage, forState: UIControlState.Normal)
            let voiceOverToRemove = MediaController.sharedMediaController.getPathForFileInDocumentsDirectory(self.scene.voiceOver).path!
            do {
                try NSFileManager.defaultManager().removeItemAtPath(voiceOverToRemove)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            self.scene.voiceOver = self.defaultVoiceOverFile
                    }
        self.sceneButtons[DESTROY_BUTTONS]![sender.tag - 1].alpha = 0
        self.sceneButtons[DESTROY_BUTTONS]![sender.tag - 1].enabled = false
        MediaController.sharedMediaController.saveScenes()
    }
    
    
    @IBAction func previewSelection(sender: AnyObject) {
        MediaController.sharedMediaController.prepareMedia(nil, media: [self.scene], movie: false, save: false)
        if let preview = MediaController.sharedMediaController.preview {
            self.videoPlayer = AVPlayer(playerItem: preview)
            self.vpVC.player = videoPlayer
            vpVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
            self.view.window?.rootViewController?.presentViewController(self.vpVC, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func saveScene(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveCompleted:", name: MediaController.Notifications.saveSceneFinished, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveFailed:", name: MediaController.Notifications.saveSceneFailed, object: nil)
        self.savingProgress.alpha = 1
        self.savingProgress.startAnimating()
        self.view.alpha = 0.6
        MediaController.sharedMediaController.prepareMedia(nil, media: [self.scene], movie: false, save: true)
    }
    
    // MARK: Save notifications
    func saveCompleted(notification: NSNotification) {
        self.savingProgress.stopAnimating()
        self.savingProgress.alpha = 0
        self.view.alpha = 1
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.saveSceneFailed, object: nil)
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
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.saveSceneFinished, object: nil)
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
        if segue.identifier == selectingShotSegueID {
            let destinationVC = segue.destinationViewController as! VideosViewController
            destinationVC.segueID = self.shotSelectedSegueID
            destinationVC.shotNumber = self.assetRequestNumber
        } else if segue.identifier == self.selectingVoiceOverSegueID {
            let destinationVC = segue.destinationViewController as! VoiceOverViewController
            destinationVC.sceneID = self.sceneNumber
            destinationVC.audioSaveID = "\(MediaController.sharedMediaController.project) scene\(self.sceneNumber)"
        }
    }
    
    
    @IBAction func sceneShotUnwindSegue(unwindSegue: UIStoryboardSegue) {
        
    }
    
    @IBAction func sceneAudioUnwindSegue(unwindSegue: UIStoryboardSegue){
        if self.audioAsset != nil {
            self.scene.voiceOver = self.audioAsset.lastPathComponent!
        }
    }
}

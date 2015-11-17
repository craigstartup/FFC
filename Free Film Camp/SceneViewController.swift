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
    @IBOutlet var scene1Buttons: Array<UIButton>!
    @IBOutlet var scene2Buttons: Array<UIButton>!
    @IBOutlet var scene3Buttons: Array<UIButton>!
    
    @IBOutlet var scene1RemoveMediaButtons: Array<UIButton>!
    @IBOutlet var scene2RemoveMediaButtons: Array<UIButton>!
    @IBOutlet var scene3RemoveMediaButtons: Array<UIButton>!
    
    var sceneButtons = [[[UIButton]?]]()
    
    //Button types
    let ADD_BUTTONS = 0
    let DESTROY_BUTTONS = 1
    let SHOT1 = 0, SHOT2 = 1, SHOT3 = 2, VOICEOVER = 3
    
    var vpVC = AVPlayerViewController()
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    
    var videoPlayer: AVPlayer!
    
    // Scene specific identifiers
    var shotSelectedSegueID:       String!
    var voiceOverSelectedSegueID:  String!
    var selectingShotSegueID:      String!
    var selectingVoiceOverSegueID: String!
    var sceneNumber:        Int!
    var assetRequestNumber: Int!
    var scene: Scene!
    
    var selectedVideoAsset: NSURL!
    var selectedVideoImage: UIImage!
    var audioAsset: NSURL!
    // placeholder values
    let defaultImage = UIImage(named: "plus_white_69")
    let defaultURL = NSURL(string: "placeholder")
    
    // MARK: View Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch(self.restorationIdentifier!) {
        case "scene1":
            self.shotSelectedSegueID = "s1ClipSelectedSegue"
            self.voiceOverSelectedSegueID = "s1AudioSelectedSegue"
            self.selectingShotSegueID = "s1SelectClip"
            self.selectingVoiceOverSegueID = "s1SelectAudio"
            self.sceneNumber = 0
            break
        case "scene2":
            self.shotSelectedSegueID = "s2ClipSelectedSegue"
            self.voiceOverSelectedSegueID = "s2AudioSelectedSegue"
            self.selectingShotSegueID = "s2SelectClip"
            self.selectingVoiceOverSegueID = "s2SelectAudio"
            self.sceneNumber = 1
            break
        case "scene3":
            self.shotSelectedSegueID = "s3ClipSelectedSegue"
            self.voiceOverSelectedSegueID = "s3AudioSelectedSegue"
            self.selectingShotSegueID = "s3SelectClip"
            self.selectingVoiceOverSegueID = "s3SelectAudio"
            self.sceneNumber = 2
            break
        default:
            print("NO MATCH")
        }
        if MediaController.sharedMediaController.scenes.isEmpty {
            guard let scenes = MediaController.sharedMediaController.loadScenes() else {
                for _ in 0..<3 {
                    let scene = Scene(shotVideos: Array(count: 3, repeatedValue: defaultURL!), shotImages: Array(count: 3, repeatedValue: defaultImage!), voiceOver: defaultURL!)
                    MediaController.sharedMediaController.scenes.append(scene!)
                }
                return
            }
            MediaController.sharedMediaController.scenes = scenes
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        defer {
            self.assetRequestNumber = nil
            self.selectedVideoImage = nil
            self.selectedVideoAsset = nil
        }
        
        self.sceneButtons = [[self.scene1Buttons, self.scene1RemoveMediaButtons],[self.scene2Buttons, self.scene2RemoveMediaButtons], [self.scene3Buttons, self.scene3RemoveMediaButtons]]
        
        for button in self.sceneButtons[self.sceneNumber][DESTROY_BUTTONS]! {
            button.alpha = 0
            button.enabled = false
        }
        
        self.navigationController?.navigationBarHidden = true
        self.scene = MediaController.sharedMediaController.scenes[sceneNumber]
        
        if assetRequestNumber != nil && self.selectedVideoAsset != nil && self.selectedVideoImage != nil {
            self.scene.shotImages[assetRequestNumber - 1] = self.selectedVideoImage
            self.scene.shotVideos[assetRequestNumber - 1] = self.selectedVideoAsset
            MediaController.sharedMediaController.saveScenes()
        }
        
        for var i = 0; i < self.sceneButtons.count ; i++ {
            let images = self.scene.shotImages
            let videos = self.scene.shotVideos
            if images.count > i && videos[i] != self.defaultURL {
                self.sceneButtons[sceneNumber][ADD_BUTTONS]![i].setImage(images[i], forState: UIControlState.Normal)
                self.sceneButtons[sceneNumber][ADD_BUTTONS]![i].contentMode = UIViewContentMode.ScaleAspectFit
                self.sceneButtons[sceneNumber][ADD_BUTTONS]![i].contentVerticalAlignment = UIControlContentVerticalAlignment.Center
                if self.sceneButtons[sceneNumber][ADD_BUTTONS]![i].currentImage != defaultImage {
                    self.sceneButtons[sceneNumber][DESTROY_BUTTONS]![i].alpha = 1
                    self.sceneButtons[sceneNumber][DESTROY_BUTTONS]![i].enabled = true
                }
            }
        }
        
        if self.scene.voiceOver != defaultURL {
            let check = UIImage(named: "Check")
            self.sceneButtons[self.sceneNumber!][ADD_BUTTONS]![VOICEOVER].setImage(check, forState: UIControlState.Normal)
            self.sceneButtons[self.sceneNumber][DESTROY_BUTTONS]![VOICEOVER].alpha = 1
            self.sceneButtons[self.sceneNumber][DESTROY_BUTTONS]![VOICEOVER].enabled = true
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
        
        self.sceneButtons[self.sceneNumber][DESTROY_BUTTONS]![buttonPressed].alpha = 1
        self.sceneButtons[self.sceneNumber][DESTROY_BUTTONS]![buttonPressed].enabled = true
        
        if buttonPressed > SHOT3 {
            scene.voiceOver = defaultURL!
            self.audioAsset = nil
        } else {
            self.selectedVideoAsset = nil
            self.performSegueWithIdentifier(self.selectingShotSegueID, sender: self)
        }
    }
    
    
    @IBAction func removeMedia(sender: AnyObject) {
        if sender.tag < 4 {
            self.scene.shotVideos[sender.tag - 1] = self.defaultURL!
            self.scene.shotImages[sender.tag - 1] = self.defaultImage!
            self.sceneButtons[self.sceneNumber][ADD_BUTTONS]![sender.tag - 1].contentVerticalAlignment = UIControlContentVerticalAlignment.Center
            self.sceneButtons[self.sceneNumber][ADD_BUTTONS]![sender.tag - 1].imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            self.sceneButtons[self.sceneNumber][ADD_BUTTONS]![sender.tag - 1].setImage(self.scene.shotImages[sender.tag - 1], forState: UIControlState.Normal)
        } else if sender.tag == 4 {
            self.sceneButtons[self.sceneNumber][ADD_BUTTONS]![VOICEOVER].contentVerticalAlignment = UIControlContentVerticalAlignment.Center
            self.sceneButtons[self.sceneNumber][ADD_BUTTONS]![VOICEOVER].imageView?.contentMode = UIViewContentMode.ScaleAspectFit
            self.sceneButtons[self.sceneNumber][ADD_BUTTONS]![VOICEOVER].setImage(self.defaultImage, forState: UIControlState.Normal)
            self.scene.voiceOver = self.defaultURL!
        }
        self.sceneButtons[self.sceneNumber][DESTROY_BUTTONS]![sender.tag - 1].alpha = 0
        self.sceneButtons[self.sceneNumber][DESTROY_BUTTONS]![sender.tag - 1].enabled = false
        MediaController.sharedMediaController.saveScenes()
    }
    
    
    @IBAction func recordVoiceOver(sender: AnyObject) {
        
    }
    
    
    @IBAction func previewSelection(sender: AnyObject) {
        MediaController.sharedMediaController.prepareMedia([self.scene], movie: false, save: false)
        if let preview = MediaController.sharedMediaController.preview {
            self.videoPlayer = AVPlayer(playerItem: preview)
            self.vpVC.player = videoPlayer
            vpVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
            presentViewController(vpVC, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func saveScene(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveCompleted:", name: MediaController.Notifications.saveSceneFinished, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveFailed:", name: MediaController.Notifications.saveSceneFailed, object: nil)
        self.savingProgress.alpha = 1
        self.savingProgress.startAnimating()
        self.view.alpha = 0.6
        MediaController.sharedMediaController.prepareMedia([self.scene], movie: false, save: true)
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
            destinationVC.segueID = self.voiceOverSelectedSegueID
        }
    }
    
    @IBAction func s1ClipUnwindSegue(unwindSegue: UIStoryboardSegue) {
        
    }
    
    @IBAction func s1AudioUnwindSegue(unwindSegue: UIStoryboardSegue){
        if self.audioAsset != nil {
            
            self.scene.voiceOver = self.audioAsset
            //MediaController.sharedMediaController.saveScenes()
        }
    }
    
    
    @IBAction func s2ClipUnwindSegue(unwindSegue: UIStoryboardSegue) {
        
    }
    
    
    @IBAction func s2AudioUnwindSegue(unwindSegue: UIStoryboardSegue){
        if self.audioAsset != nil {
            
            self.scene.voiceOver = self.audioAsset
            //MediaController.sharedMediaController.saveScenes()
        }
    }
    
    
    @IBAction func s3ClipUnwindSegue(unwindSegue: UIStoryboardSegue) {
        
    }
    
    
    @IBAction func s3AudioUnwindSegue(unwindSegue: UIStoryboardSegue){
        if self.audioAsset != nil {
            
            self.scene.voiceOver = self.audioAsset
            //MediaController.sharedMediaController.saveScenes()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

//  SelectionViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 11/1/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Social
import SwiftyDropbox

class SelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    enum TabButtons {
        static let INTRO   = 1
        static let SCENE_1 = 2
        static let SCENE_2 = 3
        static let SCENE_3 = 4
        static let MOVIE   = 5
    }
    
    
    @IBOutlet weak var toolViewContainer: UIView!
    @IBOutlet weak var tableViewControllerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var buttons: Array<UIButton>!
    @IBOutlet weak var savingProgress: UIActivityIndicatorView!
    
    var projectChanged = false
    var cellClearedCount = 0
    let defaultImage         = UIImage(named: "plus_white_69")
    let defaultVideoURL      = NSURL(string: "placeholder")
    let defaultVoiceOverFile = "placeholder"

    var viewControllers      = [UIViewController]()
    let socialSharing        = SocialController()
    var audioPlayer: AVAudioPlayer!
    var vpVC                 = AVPlayerViewController()
    let viewControllerIds    = ["IntroViewController","SceneViewController","MovieBuilderViewController"]
    
    let transitionQueue      = dispatch_queue_create("com.trans.Queue", nil)
    
    var photosPost   = false
    var facebookPost = false
    var twitterPost  = false
    var dropboxPost  = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "dropboxComplete:",
            name: MediaController.Notifications.dropBoxUpFinish,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "projectChanged:",
            name: MediaController.Notifications.projectSelected,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "viewWasDismissed:",
            name: MediaController.Notifications.toolViewDismissed,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "voiceoverCalled:",
            name: MediaController.Notifications.voiceoverCalled,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "shotCalled:",
            name: MediaController.Notifications.selectShotCalled,
            object: nil)
        
        self.navigationController?.navigationBarHidden = true
        
        self.tableView.delegate   = self
        self.tableView.dataSource = self
        self.savingProgress.alpha = 0
        
        self.getViewControllersForPages()
    }
    
    // MARK: Scrollview setup methods
    func getViewControllersForPages() {
        // Load scenes or initialize if none exist.
        MediaController.sharedMediaController.scenes = MediaController.sharedMediaController.loadScenes()
        
        if MediaController.sharedMediaController.scenes.isEmpty {
            for _ in 0..<3 {
                let scene = Scene(shotVideos: Array(count: 3, repeatedValue: defaultVideoURL!), shotImages: Array(count: 3, repeatedValue: defaultImage!), voiceOver: defaultVoiceOverFile)
                MediaController.sharedMediaController.scenes.append(scene!)
            }
        }
        
        var index = 0
        
        for viewId in self.viewControllerIds {
            if viewId == "SceneViewController" {
                for var i = 0; i < MediaController.sharedMediaController.scenes.count; i += 1 {
                    let sceneViewController = self.storyboard?.instantiateViewControllerWithIdentifier(viewId) as? SceneViewController
                    sceneViewController!.sceneNumber = i
                    sceneViewController!.index = index
                    self.viewControllers.append(sceneViewController!)
                    index += 1
                }
            } else {
                var viewController: UIViewController!
                
                if viewId == "IntroViewController" {
                    let introViewController = self.storyboard?.instantiateViewControllerWithIdentifier(viewId) as? IntroViewController
                    introViewController!.index = index
                    viewController = introViewController
                } else if viewId == "MovieBuilderViewController" {
                    let movieViewController = self.storyboard?.instantiateViewControllerWithIdentifier(viewId) as? MovieBuilderViewController
                    movieViewController!.index = index
                    viewController = movieViewController
                }
                
                self.viewControllers.append(viewController!)
                index += 1
            }
        }
    }
    
    // MARK: Button Actions
    @IBAction func projectsButtonPressed(sender: UIButton) {
        UIView.animateWithDuration(1) { () -> Void in
            self.toolViewContainer.frame.origin.x = self.tableView.frame.origin.x
        }
        
        self.buttonsOn(on: false)
    }
    
    @IBAction func shareButtonPressed(sender: UIButton) {
        self.progressSwitch(on: true)
        
        let shareView = UIAlertController(
            title: "Post Movie",
            message: "Choose a place to post/save movie.",
            preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
            self.progressSwitch(on: false)
        }
        let photosAction = UIAlertAction(title: "Save to Photos", style: .Default) { (action) -> Void in
            self.photosPost = true
            MediaController.sharedMediaController.prepareMediaFor(scene: nil, movie: true, save: true)
        }
        let dropboxAction = UIAlertAction(title: "Save to Dropbox", style: .Default) { (action) -> Void in
            self.dropboxPost = true
            
            if Dropbox.authorizedClient == nil {
                Dropbox.authorizeFromController(self)
            }
            
            MediaController.sharedMediaController.prepareMediaFor(scene: nil, movie: true, save: false)
        }
        let facebookAction = UIAlertAction(title: "Post to Facebook", style: .Default) { (action) -> Void in
            self.facebookPost = true
            MediaController.sharedMediaController.prepareMediaFor(scene: nil, movie: true, save: false)
        }
        let twitterAction = UIAlertAction(title: "Post to Twitter", style: .Default) { (action) -> Void in
            self.twitterPost = true
            MediaController.sharedMediaController.prepareMediaFor(scene: nil, movie: true, save: false)
        }
        
        let actions = [cancelAction, photosAction, dropboxAction, facebookAction, twitterAction]
        
        for action in actions {
            shareView.addAction(action)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "movieReady:",
            name: MediaController.Notifications.movieReady,
            object: nil)
        
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "saveCompleted:",
            name: MediaController.Notifications.saveMovieFinished,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "saveFailed:",
            name: MediaController.Notifications.saveMovieFailed,
            object: nil)
        
        self.vpVC.player          = nil
        self.progressSwitch(on: true)
        self.presentViewController(shareView, animated: true, completion: nil)
    }
    
    @IBAction func previewMoviePressed(sender: UIButton) {
        self.vpVC.player = nil
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "firePreview:",
            name: MediaController.Notifications.previewReady,
            object: nil)
        
        if self.audioPlayer != nil {
            self.audioPlayer.stop()
        }
        
        self.progressSwitch(on: true)
        MediaController.sharedMediaController.prepareMediaFor(scene: nil, movie: true, save: false)
    }
    
    // MARK: Helper Methods
    func progressSwitch(on on: Bool) {
        if on {
            self.savingProgress.alpha = 1
            self.savingProgress.startAnimating()
            self.view.alpha = 0.6
        } else {
            self.savingProgress.stopAnimating()
            self.savingProgress.alpha = 0
            self.view.alpha = 1
        }
    }
    
    func buttonsOn(on on: Bool) {
        let visibility: CGFloat = on ? 1 : 0.5
        let active = on ? true : false
        
        for button in self.buttons {
            button.enabled = active
            button.alpha = visibility
        }
    }

    // MARK: Table view delegate methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewControllers.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == self.viewControllers.count - 1 {
            return CGFloat(self.tableView.bounds.height)
        }
        return CGFloat(self.tableView.bounds.height * 0.8)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("viewCell") as! SelectionViewCell
        
        if cell.cellViewView.subviews.count > 0 && self.projectChanged {
            for view in cell.cellViewView.subviews {
                view.removeFromSuperview()
            }
            
            self.cellClearedCount += 1
        }
        
        let view = self.viewControllers[indexPath.row].view
        view.frame = cell.cellViewView.bounds
        cell.cellViewView.addSubview(view)
        
        if cellClearedCount == self.viewControllers.count {
            self.projectChanged = false
            self.cellClearedCount = 0
        }
        
        return cell
    }
    
    // MARK: Notification methods
    func dropboxComplete(notification: NSNotification) {
        let dropboxAlert = UIAlertController(
            title: "Dropbox Upload Complete",
            message: "Video uploaded to app Dropbox folder",
            preferredStyle: .Alert)
        
        let okAction = UIAlertAction(
            title: "OK",
            style: .Default,
            handler: { (action) -> Void in
                NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.dropBoxUpFinish, object: nil)
        })
        
        dropboxAlert.addAction(okAction)
        self.presentViewController(dropboxAlert, animated: true, completion: nil)
    }
    
    func projectChanged(notification: NSNotification) {
        self.buttonsOn(on: true)
        
        self.projectChanged = true
        self.viewControllers.removeAll()
        self.getViewControllersForPages()
        self.tableView.reloadData()
        
        UIView.animateWithDuration(1) { () -> Void in
            self.toolViewContainer.frame.origin.x = self.toolViewContainer.frame.origin.x - 600
        }
    }
    
    func firePreview(notification: NSNotification) {
        if MediaController.sharedMediaController.preview != nil {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.progressSwitch(on: false)
                let videoPlayer = AVPlayer(playerItem: MediaController.sharedMediaController.preview)
                self.vpVC.player = videoPlayer
                self.vpVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
                self.view.window?.rootViewController?.presentViewController(self.vpVC, animated: true, completion: nil)
            })
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: MediaController.Notifications.previewReady,
            object: nil)
        
        // Make share button enabled
    }
    
    // MARK: Buttons state
    func viewWasDismissed(notification: NSNotification) {
        self.buttonsOn(on: true)
    }
    
    func shotCalled(notification: NSNotification) {
        self.buttonsOn(on: false)
        self.buttons.last!.alpha = 1
    }
    
    func voiceoverCalled(notification: NSNotification) {
        self.buttonsOn(on: false)
    }
    
    // MARK: Save and share
    func movieReady(notification: NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: MediaController.Notifications.movieReady,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "movieShared:",
            name: MediaController.Notifications.sharingComplete,
            object: nil)
        
        
        let videoURL = MediaController.sharedMediaController.movieToShare
        self.socialSharing.postMovieToFacebook(videoURL)
    }
    
    func movieShared(notification: NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: MediaController.Notifications.sharingComplete,
            object: nil)
        
        self.progressSwitch(on: false)
    }
    
    func saveCompleted(notification: NSNotification) {
        self.progressSwitch(on: false)
        
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: MediaController.Notifications.saveMovieFinished,
            object: nil)
        
        var message: String
        
        if MediaController.sharedMediaController.dropboxIsLoading == false {
            message = "Movie saved to Photos!"
        } else {
            message = "Movie saved to Photos! Video is being uploaded to Dropbox. Please do not close the app until you are notified that it is complete"
        }
        
        let alertSuccess = UIAlertController(
            title: "Success",
            message: message,
            preferredStyle: .Alert)
        let okAction = UIAlertAction(
            title: "Thanks!",
            style: .Default) { (action) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alertSuccess.addAction(okAction)
        self.presentViewController(alertSuccess, animated: true, completion: nil)
    }
    
    func saveFailed(notification: NSNotification) {
        self.progressSwitch(on: false)
        
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: MediaController.Notifications.saveMovieFailed,
            object: nil)
        
        let alertFailure = UIAlertController(
            title: "Failure",
            message: "Movie failed to save. Re-select media and try again", preferredStyle: .Alert)
        let okAction = UIAlertAction(
            title: "Thanks!",
            style: .Default) { (action) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alertFailure.addAction(okAction)
        self.presentViewController(alertFailure, animated: true, completion: nil)
        MediaController.sharedMediaController.dropboxIsLoading = false
    }
}

//  SelectionViewController.swift
//  Film Camp
//
//  Created by Eric Mentele on 11/1/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Social
import SwiftyDropbox

class SelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var toolViewContainer: UIView!
    @IBOutlet weak var blockerView: UIView!
    @IBOutlet weak var tableViewControllerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var buttons: Array<UIButton>!
    @IBOutlet var buttonLabels: Array<UILabel>!
    @IBOutlet weak var savingProgress: UIActivityIndicatorView!
    
    var projectChanged = false
    var cellClearedCount = 0
    let defaultImage         = UIImage(named: "Add Shot 1")
    let defaultVideoURL      = NSURL(string: "placeholder")
    let defaultVoiceOverFile = "placeholder"

    var viewControllers      = [UIViewController]()
    let socialSharing        = SocialController()
    let viewControllerIds    = ["IntroViewController","SceneViewController","MovieBuilderViewController"]
    
    let transitionQueue      = dispatch_queue_create("com.trans.Queue", nil)
    
    var photosPost   = false
    var facebookPost = false
    var dropboxPost  = false
    var service: String!
    var playTimer: NSTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        
        self.getViewControllersForPages()
    }
    
    // MARK: Tableview setup methods
    func getViewControllersForPages() {
        // Load scenes or initialize if none exist.
        MediaController.sharedMediaController.loadScenes()
        
        let movieExtras = MediaController.sharedMediaController.movieEnds
        var introIsPresent:Bool = movieExtras["intro"]!
        var musicIsPresent:Bool = movieExtras["music"]!
        let numberOfScenes = MediaController.sharedMediaController.numberOfScenes
        
        if MediaController.sharedMediaController.scenes.isEmpty {
            for _ in 0..<numberOfScenes {
                let scene = Scene(shotVideos: Array(count: 3, repeatedValue: defaultVideoURL!), shotImages: Array(count: 3, repeatedValue: defaultImage!), voiceOver: defaultVoiceOverFile)
                MediaController.sharedMediaController.scenes.append(scene!)
            }
            MediaController.sharedMediaController.saveScenes()
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
                
                if viewId == "IntroViewController" && introIsPresent == true {
                    let introViewController = self.storyboard?.instantiateViewControllerWithIdentifier(viewId) as? IntroViewController
                    introViewController!.index = index
                    viewController = introViewController
                    introIsPresent = false
                    self.viewControllers.append(viewController!)
                } else if viewId == "MovieBuilderViewController" && musicIsPresent == true {
                    let movieViewController = self.storyboard?.instantiateViewControllerWithIdentifier(viewId) as? MovieBuilderViewController
                    movieViewController!.index = index
                    viewController = movieViewController
                    musicIsPresent = false
                    self.viewControllers.append(viewController!)
                }
            
                index += 1
            }
        }
    }
    
    // MARK: Button Actions
    @IBAction func projectsButtonPressed(sender: UIButton) {
        UIView.animateWithDuration(0.6) { () -> Void in
            self.toolViewContainer.frame.origin.x = self.tableView.frame.origin.x
        }
        
        self.buttonsOn(on: false)
    }
    
    @IBAction func cameraButtonPressed(sender: AnyObject) {
        self.performSegueWithIdentifier("cameraSegue", sender: self)
    }
    
    @IBAction func shareButtonPressed(sender: UIButton) {
        self.progressSwitch(on: true)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "movieReady:",
            name: MediaController.Notifications.movieReady,
            object: nil)
        
        self.progressSwitch(on: true)
        let shareView: UIAlertController = self.getShareView()
        self.presentViewController(shareView, animated: true, completion: nil)
    }
    
    @IBAction func previewMoviePressed(sender: UIButton) {
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "firePreview:",
            name: MediaController.Notifications.previewReady,
            object: nil)
        
        self.progressSwitch(on: true)
        MediaController.sharedMediaController.prepareMediaFor(scene: nil, movie: true, save: false)
    }
    
    // MARK: Helper Methods
    func progressSwitch(on on: Bool) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if on {
                self.savingProgress.alpha = 1
                self.savingProgress.startAnimating()
                self.blockerView.userInteractionEnabled = true
                self.blockerView.alpha = 0.35
            } else {
                self.savingProgress.stopAnimating()
                self.savingProgress.alpha = 0
                self.blockerView.userInteractionEnabled = false
                self.blockerView.alpha = 0
            }
        }
        
    }
    
    func buttonsOn(on on: Bool) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            let visibility: CGFloat = on ? 1 : 0.5
            let active = on ? true : false
            
            for button in self.buttons {
                button.enabled = active
                button.alpha = visibility
            }
            
            for label in self.buttonLabels {
                label.alpha = visibility
            }
        }
    }
    
    func getShareView() -> UIAlertController {
        let shareView = UIAlertController(
            title: "Post Movie",
            message: "Choose a place to post/save movie.",
            preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
            self.progressSwitch(on: false)
        }
        
        let photosAction = UIAlertAction(title: "Save to Photos", style: .Default) { (action) -> Void in
            self.photosPost = true
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveFailed:", name: MediaController.Notifications.saveMovieFailed, object: nil)
            MediaController.sharedMediaController.albumTitle = MediaController.Albums.movies
            MediaController.sharedMediaController.prepareMediaFor(scene: nil, movie: true, save: true)
        }
        
        let dropboxAction = UIAlertAction(title: "Save to Dropbox", style: .Default) { (action) -> Void in
            self.dropboxPost = true
            self.service = "Dropbox"
            
            if Dropbox.authorizedClient == nil {
                Dropbox.authorizeFromController(self)
                self.progressSwitch(on: false)
            }
            
            MediaController.sharedMediaController.prepareMediaFor(scene: nil, movie: true, save: false)
            
        }
        
        let facebookAction = UIAlertAction(title: "Post to Facebook", style: .Default) { (action) -> Void in
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: "facebookSetupNeeded:",
                name: MediaController.Notifications.noSocialSetup,
                object: nil)
            
            self.facebookPost = true
            self.service = "Facebook"
            MediaController.sharedMediaController.prepareMediaFor(scene: nil, movie: true, save: false)
        }
        
        let actions = [cancelAction, photosAction, dropboxAction, facebookAction]
        
        for action in actions {
            shareView.addAction(action)
        }
        
        return shareView
    }

    // MARK: Table view delegate methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print("View Controllers are = to:")
        //print(self.viewControllers.count)
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
    func projectChanged(notification: NSNotification) {
        self.buttonsOn(on: true)
        
        self.projectChanged = true
        self.viewControllers.removeAll()
        self.getViewControllersForPages()
        self.tableView.reloadData()
        
        UIView.animateWithDuration(0.6) { () -> Void in
            self.toolViewContainer.frame.origin.x = self.toolViewContainer.frame.origin.x + self.view.frame.width + 100
        }
    }
    
    func firePreview(notification: NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: MediaController.Notifications.previewReady,
            object: nil)
       
            self.progressSwitch(on: false)
            let vpVC = MediaController.sharedMediaController.playerForPreview()
        
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.presentViewController(vpVC, animated: true, completion: nil)
            }
    }

    func facebookSetupNeeded(notifictaion: NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.noSocialSetup, object: nil)
        self.facebookPost = false
        self.progressSwitch(on: false)
        let facebookSetupAlert = UIAlertController(title: "Facebook Setup", message: "Please setup Facebook in your device settings and try again.", preferredStyle: .Alert)
        let ok = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        facebookSetupAlert.addAction(ok)
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.presentViewController(facebookSetupAlert, animated: true, completion: nil)
        }
    }

    
    // MARK: Buttons state notification methods
    func viewWasDismissed(notification: NSNotification) {
        self.buttonsOn(on: true)
    }
    
    func shotCalled(notification: NSNotification) {
        self.buttonsOn(on: false)
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.buttons![1].alpha = 1
            self.buttons![1].enabled = true
            self.buttonLabels![1].alpha = 1
        }
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
        
        let videoURL = MediaController.sharedMediaController.movieToShare
        
        if self.facebookPost || self.dropboxPost {
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: "movieShared:",
                name: MediaController.Notifications.sharingComplete,
                object: nil)
        }
        
        if self.facebookPost {
            self.socialSharing.postMovieToFacebook(videoURL)
            self.facebookPost = false
        } else if dropboxPost {
            MediaController.sharedMediaController.saveToDropBox(videoURL)
            self.dropboxPost = false
        } else if photosPost {
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
        }
    }
    
    func movieShared(notification: NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: MediaController.Notifications.sharingComplete,
            object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.noSocialSetup, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "uploadComplete:",
            name: MediaController.Notifications.uploadComplete,
            object: nil)
        
        self.progressSwitch(on: false)
        let uploadAlert = UIAlertController(
            title: "Uploading Video",
            message: "Video being uploaded to \(service). Do not close the app until you are notified that this is done.",
            preferredStyle: .Alert)
        
        let okAction = UIAlertAction(
            title: "OK",
            style: .Default,
            handler: nil)
        
        uploadAlert.addAction(okAction)
        self.presentViewController(uploadAlert, animated: true, completion: nil)
    }
    
    func uploadComplete(notification: NSNotification) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.uploadComplete, object: nil)
        let uploadAlert = UIAlertController(
            title: "Upload Complete",
            message: "Video uploaded to \(service)",
            preferredStyle: .Alert)
        
        let okAction = UIAlertAction(
            title: "OK",
            style: .Default,
            handler: nil)
        
        uploadAlert.addAction(okAction)
        self.presentViewController(uploadAlert, animated: true, completion: nil)
    }
    
    func saveCompleted(notification: NSNotification) {
        self.progressSwitch(on: false)
        
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: MediaController.Notifications.saveMovieFinished,
            object: nil)
        
        let message = "Movie saved to Photos!"
        
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
    }
}

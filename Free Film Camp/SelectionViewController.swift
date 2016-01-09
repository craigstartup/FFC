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

class SelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    enum TabButtons {
        static let INTRO   = 1
        static let SCENE_1 = 2
        static let SCENE_2 = 3
        static let SCENE_3 = 4
        static let MOVIE   = 5
    }
    
    
    @IBOutlet weak var tableViewControllerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var buttons: Array<UIButton>!
    @IBOutlet weak var savingProgress: UIActivityIndicatorView!
    
    var lastSegue: String!
    
    let defaultImage         = UIImage(named: "plus_white_69")
    let defaultVideoURL      = NSURL(string: "placeholder")
    let defaultVoiceOverFile = "placeholder"

    var viewControllers      = [UIViewController]()
    let socialSharing = SocialController()
    var audioPlayer: AVAudioPlayer!
    var vpVC = AVPlayerViewController()
    var scrollViewPages      = [CGRect]()
    let viewControllerIds    = ["IntroViewController","SceneViewController","MovieBuilderViewController"]
    
    var currentVC = 0
    var currentButton = 0
    let transitionQueue = dispatch_queue_create("com.trans.Queue", nil)
    
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
            name: "projectSelected", 
            object: nil)
        
        self.navigationController?.navigationBarHidden = true
        
        self.tableView.delegate = self
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

    @IBAction func projectsButtonPressed(sender: UIButton) {
        // set up projects view to cover tableview
    
        let projectsVC = self.storyboard?.instantiateViewControllerWithIdentifier("projectsNav") as! UINavigationController
        let projectsView = projectsVC.view
        let relativeFrame = self.tableView.bounds
        let startingFrame = CGRectMake(relativeFrame.origin.x - relativeFrame.size.width, relativeFrame.origin.y, relativeFrame.size.width, relativeFrame.size.height)
        projectsView.frame = startingFrame
        self.view.addSubview(projectsView)
        
        // present over table veiw and disable buttons until project selected and view dismissed
        UIView.animateWithDuration(1) { () -> Void in
            projectsVC.view.frame = self.tableView.bounds
        }
    }
    
    @IBAction func shareButtonPressed(sender: UIButton) {
        self.progressSwitch(on: true)
        
        if MediaController.sharedMediaController.intro == nil {
            MediaController.sharedMediaController.prepareMedia(
                intro: false,
                media: MediaController.sharedMediaController.scenes,
                movie: true,
                save: false)
        } else {
            MediaController.sharedMediaController.prepareMedia(
                intro: true,
                media: MediaController.sharedMediaController.scenes,
                movie: true,
                save: false)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "movieReady:", name: MediaController.Notifications.movieReady, object: nil)
        
        self.vpVC.player          = nil
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
        
        self.progressSwitch(on: true)
        
        if MediaController.sharedMediaController.intro == nil {
            MediaController.sharedMediaController.prepareMedia(
                intro: false,
                media: MediaController.sharedMediaController.scenes,
                movie: true,
                save: true
            )
        } else {
            MediaController.sharedMediaController.prepareMedia(
                intro: true,
                media: MediaController.sharedMediaController.scenes,
                movie: true,
                save: true
            )
        }
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
        
        if MediaController.sharedMediaController.intro == nil {
            MediaController.sharedMediaController.prepareMedia(
                intro: false,
                media: MediaController.sharedMediaController.scenes,
                movie: true,
                save: false)
        } else {
            MediaController.sharedMediaController.prepareMedia(
                intro: true,
                media: MediaController.sharedMediaController.scenes,
                movie: true,
                save: false)
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
    
    // MARK: Notification handlers
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

    // MARK: Table view delegate methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewControllers.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(self.tableView.bounds.height / 1.3)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("viewCell") as! SelectionViewCell
        let view = self.viewControllers[indexPath.row].view
        view.frame = cell.cellViewView.bounds
        cell.cellViewView.addSubview(view)
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
        
        self.viewControllers.removeAll()
        self.getViewControllersForPages()
    }
}

//
//  MovieBuilderViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/5/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import Photos
import AVKit
import AVFoundation
import Social


class MovieBuilderViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: Properties
    @IBOutlet weak var savingProgress: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    
    var audioPlayer: AVAudioPlayer!
    var audioFileURL: NSURL!
    var currentCell: NSIndexPath!
    var vpVC = AVPlayerViewController()
    var videoPlayer: AVPlayer!
    let socialSharing = SocialController()
    let musicFileNames = ["Believe in your dreams", "Sounds like fun", "Youve got mail"]
    var index: Int!
    
    // MARK: View lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate                          = self
        tableView.dataSource                        = self

        guard let loadedIntro                       = MediaController.sharedMediaController.loadIntro()
            else {
                print("No intro!")
                return
        }
        MediaController.sharedMediaController.intro = loadedIntro
        
    }
    
    override func viewWillAppear(animated: Bool) {
        MediaController.sharedMediaController.albumTitle = MediaController.Albums.movies
        self.navigationController?.navigationBarHidden   = true
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        MediaController.sharedMediaController.preview = nil
    }
    
    @IBAction func shareMovie(sender: UIButton) {
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
    }
    
    @IBAction func makeMovie(sender: AnyObject) {
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
    
    // MARK: Preview methods
    @IBAction func preview(sender: AnyObject) {
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
    
    // MARK: Tableview methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.musicFileNames.count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("musicCell")! as! MusicCell
        cell.playMusicTrackButton.alpha = 0
        cell.playMusicTrackButton.enabled = false
        cell.trackCheck.alpha = 0
        
        if indexPath.row < musicFileNames.count {
            cell.cellTitle.text = self.musicFileNames[indexPath.row]
            cell.playMusicTrackButton.tag = indexPath.row
            cell.playMusicTrackButton.addTarget(self, action: "playMusicForCell", forControlEvents: UIControlEvents.TouchUpInside)
            return cell
        } else {
            cell.cellTitle.text = "None"
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        MediaController.sharedMediaController.musicTrack = nil
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! MusicCell
        cell.playMusicTrackButton.setTitle("Play", forState: UIControlState.Selected)
        self.currentCell = indexPath
        
        if indexPath.row < musicFileNames.count {
            cell.playMusicTrackButton.alpha = 1
            cell.playMusicTrackButton.enabled = true
            cell.trackCheck.alpha = 1
            MediaController.sharedMediaController.musicTrack = AVURLAsset(URL: NSBundle.mainBundle().URLForResource(self.musicFileNames[indexPath.row], withExtension: "mp3")!)
            self.audioFileURL = NSBundle.mainBundle().URLForResource(self.musicFileNames[indexPath.row], withExtension: "mp3")
        } else {
            MediaController.sharedMediaController.musicTrack = nil
            self.audioFileURL = nil
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        print("deselected")
        
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) as! MusicCell? else {
            if audioPlayer != nil {
                self.audioPlayer.stop()
                self.audioPlayer = nil
            }
            return print("no cell")
        }
        
        cell.playMusicTrackButton.setTitle("Play", forState: UIControlState.Selected)
        
        if indexPath.row < musicFileNames.count {
            cell.playMusicTrackButton.alpha = 0
            cell.playMusicTrackButton.enabled = false
            cell.trackCheck.alpha = 0
            if audioPlayer != nil {
                self.audioPlayer.stop()
                self.audioPlayer = nil
            }
        }
        self.currentCell = nil
    }
    
    func playMusicForCell() {
        let cell = tableView.cellForRowAtIndexPath(self.currentCell) as! MusicCell
        if self.audioPlayer == nil && self.audioFileURL != nil {
            do {
                try self.audioPlayer = AVAudioPlayer(contentsOfURL: self.audioFileURL)
            } catch let audioError as NSError {
                print(audioError.localizedDescription)
            }
        }
        
        if audioPlayer?.playing == true {
            cell.playMusicTrackButton.setTitle("Play", forState: UIControlState.Selected)
            audioPlayer.stop()
        } else if audioPlayer?.playing == false{
            cell.playMusicTrackButton.setTitle("Stop", forState: UIControlState.Selected)
            self.audioPlayer.play()
        }
    }
}

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


class MovieBuilderViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var savingProgress: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    var videoPlayer: AVPlayer!
    var vpVC = AVPlayerViewController()
    var audioPlayer: AVAudioPlayer!
    var audioFileURL: NSURL!
    var currentCell: NSIndexPath!
    var previewQueue = [AVPlayerItem]()
    let musicFileNames = ["Believe in your dreams", "Sounds like fun", "Youve got mail"]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        MediaController.sharedMediaController.moviePreview = nil 
    }
    
    
    @IBAction func makeMovie(sender: AnyObject) {
        self.vpVC.player = nil
        self.videoPlayer = nil
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveCompleted:", name: MediaController.Notifications.saveMovieFinished, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveFailed", name: MediaController.Notifications.saveMovieFailed, object: nil)
        self.savingProgress.alpha = 1
        self.savingProgress.startAnimating()
        self.view.alpha = 0.6
        MediaController.sharedMediaController.prepareMovie(true)
    }
    
    func saveCompleted(notification: NSNotification) {
        self.savingProgress.stopAnimating()
        self.savingProgress.alpha = 0
        self.view.alpha = 1
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.saveMovieFinished, object: nil)
        let alertSuccess = UIAlertController(title: "Success", message: "Movie saved to Photos!", preferredStyle: .Alert)
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
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.saveMovieFailed, object: nil)
        let alertFailure = UIAlertController(title: "Failure", message: "Movie failed to save. Re-select media and try again", preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "Thanks!", style: .Default) { (action) -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alertFailure.addAction(okAction)
        self.presentViewController(alertFailure, animated: true, completion: nil)
    }
    
    @IBAction func preview(sender: AnyObject) {
        MediaController.sharedMediaController.prepareMovie(false)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "firePreview:", name: MediaController.Notifications.previewReady, object: nil)
        self.savingProgress.alpha = 1
        self.savingProgress.startAnimating()
    }
    
    func firePreview(notification: NSNotification) {
        if MediaController.sharedMediaController.moviePreview != nil {
            self.savingProgress.stopAnimating()
            self.savingProgress.alpha = 0
            self.videoPlayer = AVPlayer(playerItem: MediaController.sharedMediaController.moviePreview)
            self.vpVC.player = videoPlayer
            vpVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
            presentViewController(vpVC, animated: true, completion: nil)
        }
        NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.previewReady, object: nil)
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
        print("selected")
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! MusicCell
        cell.playMusicTrackButton.setTitle("Play", forState: UIControlState.Selected)
        self.currentCell = indexPath
        if indexPath.row < musicFileNames.count {
            cell.playMusicTrackButton.alpha = 1
            cell.playMusicTrackButton.enabled = true
            cell.trackCheck.alpha = 1
            MediaController.sharedMediaController.musicTrack = AVAsset(URL: NSBundle.mainBundle().URLForResource(self.musicFileNames[indexPath.row], withExtension: "mp3")!)
            self.audioFileURL = NSBundle.mainBundle().URLForResource(self.musicFileNames[indexPath.row], withExtension: "mp3")
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
        if self.audioPlayer == nil {
            do {
                try self.audioPlayer = AVAudioPlayer(contentsOfURL: self.audioFileURL)
            } catch let audioError as NSError {
                print(audioError.localizedDescription)
            }
        }
        if audioPlayer.playing == true {
            cell.playMusicTrackButton.setTitle("Play", forState: UIControlState.Selected)
            audioPlayer.stop()
        } else if audioPlayer.playing == false{
            cell.playMusicTrackButton.setTitle("Stop", forState: UIControlState.Selected)
            self.audioPlayer.play()
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

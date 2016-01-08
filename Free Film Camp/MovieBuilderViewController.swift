//
//  MovieBuilderViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/5/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

class MovieBuilderViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    // MARK: Properties
    @IBOutlet weak var tableView: UITableView!
    
    var audioPlayer: AVAudioPlayer!
    var audioFileURL: NSURL!
    var currentCell: NSIndexPath!
    var videoPlayer: AVPlayer!
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

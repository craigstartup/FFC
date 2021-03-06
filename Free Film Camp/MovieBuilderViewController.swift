//
//  MovieBuilderViewController.swift
//  Film Camp
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
    @IBOutlet weak var musicSelectedLabel: UIButton!
    
    var audioFileURL: NSURL!
    var currentCell: NSIndexPath!
    var videoPlayer: AVPlayer!
    
    var index: Int!
    let musicFileNames = ["Believe in your dreams", "Sounds like fun", "Youve got mail"]
    
    // MARK: View lifecycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate                          = self
        tableView.dataSource                        = self
        tableView.scrollEnabled                     = false

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
        var cellsHeight = self.tableView.rowHeight
        cellsHeight *= CGFloat(self.musicFileNames.count)
        
        var tableFrame = self.tableView.frame
        tableFrame.size.height = cellsHeight
        self.tableView.frame = tableFrame
    }

    // MARK: Tableview methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.musicFileNames.count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("musicCell")! as! MusicCell
        
        if indexPath.row < musicFileNames.count {
            cell.cellTitle.text = self.musicFileNames[indexPath.row]
            
            cell.musicURL = NSBundle.mainBundle().URLForResource(self.musicFileNames[indexPath.row], withExtension: "mp3")!
            return cell
        } else {
            cell.cellTitle.text = "None"
            cell.playMusicTrackButton.setImage(UIImage(named: "No Track"), forState: .Normal)
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        MediaController.sharedMediaController.musicTrack = nil
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! MusicCell
        cell.trackCheck.highlighted = true
        self.currentCell = indexPath
        
        if indexPath.row < musicFileNames.count {
            MediaController.sharedMediaController.musicTrack = AVURLAsset(URL: cell.musicURL)
            self.audioFileURL = cell.musicURL
            self.musicSelectedLabel.highlighted = true
        } else {
            MediaController.sharedMediaController.musicTrack = nil
            self.musicSelectedLabel.highlighted = false
            self.audioFileURL = nil
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        print("deselected")
        
        guard let cell = tableView.cellForRowAtIndexPath(indexPath) as! MusicCell? else {
            return print("no cell")
        }
        
        cell.trackCheck.highlighted = false
        
        if cell.audioPlayer != nil {
            cell.audioPlayer.stop()
        }
        
        self.currentCell = nil
    }
    
}

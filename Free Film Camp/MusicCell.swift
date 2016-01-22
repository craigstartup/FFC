//
//  musicCell.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 11/5/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//
import Foundation
import UIKit
import AVFoundation

class MusicCell: UITableViewCell {
    @IBOutlet weak var trackCheck: UIImageView!
    @IBOutlet weak var playMusicTrackButton: UIButton!
    @IBOutlet weak var cellTitle: UILabel!
    
    var audioPlayer: AVAudioPlayer!
    var musicURL: NSURL!
    
    
    @IBAction func playMusicForCell(sender: UIButton) {
        if self.audioPlayer == nil {
            do {
                try self.audioPlayer = AVAudioPlayer(contentsOfURL: self.musicURL)
            } catch let audioError as NSError {
                print(audioError.localizedDescription)
            }
        }
        
        if audioPlayer?.playing == true {
            self.playMusicTrackButton.highlighted = false
            audioPlayer.stop()
        } else if audioPlayer?.playing == false {
            self.playMusicTrackButton.highlighted = true
            self.audioPlayer.play()
        }
    }
}
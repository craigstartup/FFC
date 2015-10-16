//
//  VoiceOverViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/8/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import AVFoundation

class VoiceOverViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    var audioPlayer: AVAudioPlayer!
    var audioRecorder: AVAudioRecorder!
    var audioAssetToPass: AVAsset!
    
    var segueID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playButton.enabled = false
        stopButton.enabled = false
        doneButton.enabled = false
        
        let dirPaths =
        NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
            NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir = dirPaths[0]
        let soundFileURL = NSURL(fileURLWithPath: docsDir).URLByAppendingPathComponent("sound.caf")
        let recordSettings =
        [AVEncoderAudioQualityKey: AVAudioQuality.Min.rawValue,
            AVEncoderBitRateKey: 16,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0]
        
        do {
            
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch let error as NSError {
            
            print("audioSession error: \(error.localizedDescription)")
        }
        
        do {
            try self.audioRecorder = AVAudioRecorder(URL: soundFileURL, settings: recordSettings as! [String : AnyObject])
            audioRecorder?.prepareToRecord()
            
        } catch let error as NSError {
            
            print("audioSession error: \(error.localizedDescription)")
        }
    }
    
    
    
    @IBAction func recordButtonPressed(sender: AnyObject) {
        
        if audioPlayer?.playing == true {
            
            audioPlayer.stop()
        }
        if audioRecorder.recording == false {
            recordButton.enabled = false
            recordButton.alpha = 0.5
            playButton.enabled = false
            playButton.alpha = 0.5
            doneButton.enabled = false
            doneButton.alpha = 0.5
            stopButton.enabled = true
            stopButton.alpha = 1.0
            audioRecorder.recordForDuration(9.0)
        }
    }
    
    
    @IBAction func playButtonPressed(sender: AnyObject) {
        
        if audioRecorder.recording == false {
            stopButton.enabled = true
            stopButton.alpha = 1.0
            recordButton.enabled = false
            recordButton.alpha = 0.5
            playButton.alpha = 0.5
            
            do {
                
                try self.audioPlayer = AVAudioPlayer(contentsOfURL: (audioRecorder?.url)!)
                self.audioPlayer.play()
            } catch let error as NSError {
                
                print("audioPlayer error: \(error.localizedDescription)")
            }
            audioPlayer.delegate = self
        }
        
        playButton.alpha = 1.0
        recordButton.alpha = 1.0
        recordButton.enabled = true
    }
    
    @IBAction func stopButtonPressed(sender: AnyObject) {
        
        stopButton.enabled = false
        stopButton.alpha = 0.5
        playButton.enabled = true
        playButton.alpha = 1.0
        recordButton.enabled = true
        recordButton.alpha = 1.0
        doneButton.enabled = true
        doneButton.alpha = 1.0
        
        if audioRecorder.recording == true {
            audioRecorder.stop()
        } else if audioPlayer?.playing == true {
            audioPlayer.stop()
        }
        
    }
    
    
    @IBAction func doneButtonPressed(sender: AnyObject) {
        
        self.audioAssetToPass = AVAsset(URL: (audioRecorder?.url)!)
        self.performSegueWithIdentifier(self.segueID, sender: self)
    }
    
    // get audio file
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "s1AudioSelectedSegue" {
            
            let scene1BuilderVC = segue.destinationViewController as! FirstSceneViewController
            scene1BuilderVC.audioAsset = self.audioAssetToPass
        } else if segue.identifier == "s2AudioSelectedSegue" {
            
            let scene2BuilderVC = segue.destinationViewController as! SecondSceneViewController
            scene2BuilderVC.audioAsset = self.audioAssetToPass
        } else if segue.identifier == "s3AudioSelectedSegue" {
            
            let scene3BuilderVC = segue.destinationViewController as! ThirdSceneViewController
            scene3BuilderVC.audioAsset = self.audioAssetToPass
        }
    }
    
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        recordButton.enabled = true
        stopButton.enabled = false
    }
    
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        print("Audio Play Decode Error")
    }
    
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
    }
    
    
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {
        print("Audio Record Encode Error")
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

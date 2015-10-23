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
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var videoPreviewLayer: UIView!
    
    var audioPlayer: AVAudioPlayer!
    var audioRecorder: AVAudioRecorder!
    var audioAssetToPass: AVAsset!
    
    var segueID: String!
    
    var hasRecorded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up voice recorder
        // TODO: Cleanup temp files.
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .LongStyle
        let date = dateFormatter.stringFromDate(NSDate())
        let soundFilePath = NSTemporaryDirectory()
        let url = NSURL(fileURLWithPath: soundFilePath).URLByAppendingPathComponent("sound-\(date).caf")
        let recordSettings =
        [AVEncoderAudioQualityKey: AVAudioQuality.Min.rawValue,
            AVEncoderBitRateKey: 16,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0]
        
        do {
            
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker)
        } catch let error as NSError {
            
            print("audioSession error: \(error.localizedDescription)")
        }
        
        do {
            try self.audioRecorder = AVAudioRecorder(URL: url, settings: recordSettings as! [String : AnyObject])
            audioRecorder?.prepareToRecord()
            
        } catch let error as NSError {
            
            print("audioSession error: \(error.localizedDescription)")
        }
        self.audioRecorder.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        
        // set up initial button states
        playButton.enabled = false
        playButton.alpha = 0.4
        recordButton.alpha = 1
        recordButton.enabled = true
    }
    
    
    @IBAction func recordButtonPressed(sender: AnyObject) {
        
        self.hasRecorded = true
        if audioPlayer?.playing == true {
            
            audioPlayer.stop()
        }
        if audioRecorder.recording == false {
            recordButton.enabled = false
            recordButton.alpha = 0.5
            playButton.enabled = false
            playButton.alpha = 0.4
            doneButton.enabled = false
            doneButton.alpha = 0.4
            audioRecorder.recordForDuration(9.0)
        }
    }
    
    
    @IBAction func playButtonPressed(sender: AnyObject) {
        
        if audioRecorder.recording == false {
            recordButton.enabled = false
            recordButton.alpha = 0.5
            playButton.alpha = 0.4
            playButton.enabled = false
            
            do {
                
                try self.audioPlayer = AVAudioPlayer(contentsOfURL: (audioRecorder?.url)!)
                self.audioPlayer.play()
            } catch let error as NSError {
                
                print("audioPlayer error: \(error.localizedDescription)")
            }
            self.audioPlayer.delegate = self
        }
    }
    
    
    @IBAction func doneButtonPressed(sender: AnyObject) {
        
        if hasRecorded {
        self.audioAssetToPass = AVAsset(URL: (audioRecorder?.url)!)
        }
        
        self.performSegueWithIdentifier(self.segueID, sender: self)
    }
    
    // get audio file
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if self.audioAssetToPass != nil {
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
    }
    
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        playButton.alpha = 1.0
        playButton.enabled = true
        recordButton.alpha = 1.0
        recordButton.enabled = true
    }
    
    
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {
        
        print("Audio Play Decode Error")
    }
    
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        
        self.playButton.enabled = true
        self.playButton.alpha = 1
        self.recordButton.enabled = true
        self.recordButton.alpha = 1
        self.doneButton.enabled = true
        self.doneButton.alpha = 1
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

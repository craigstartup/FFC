//
//  VoiceOverViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/8/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
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
            try audioRecorder = AVAudioRecorder(URL: soundFileURL, settings: recordSettings as! [String : AnyObject])
            audioRecorder?.prepareToRecord()
            
        } catch let error as NSError {
            
            print("audioSession error: \(error.localizedDescription)")
        }
    }
    
    
    
    @IBAction func recordButtonPressed(sender: AnyObject) {
        
        if audioRecorder.recording == false {
            playButton.enabled = false
            doneButton.enabled = false
            stopButton.enabled = true
            audioRecorder.record()
        }
    }
    
    
    @IBAction func playButtonPressed(sender: AnyObject) {
        
        if audioRecorder.recording == false {
            stopButton.enabled = true
            recordButton.enabled = false
            
            do {
                
                try audioPlayer = AVAudioPlayer(contentsOfURL: (audioRecorder?.url)!)
                audioPlayer.play()
            } catch let error as NSError {
                
                print("audioPlayer error: \(error.localizedDescription)")
            }
            audioPlayer.delegate = self
        }
        
    }
    
    
    @IBAction func stopButtonPressed(sender: AnyObject) {
        
        stopButton.enabled = false
        playButton.enabled = true
        recordButton.enabled = true
        doneButton.enabled = true
        
        if audioRecorder.recording == true {
            audioRecorder.stop()
        } else {
            audioPlayer.stop()
        }
        
    }
    
    
    @IBAction func doneButtonPressed(sender: AnyObject) {
        
        self.audioAssetToPass = AVAsset(URL: (audioRecorder?.url)!)
        
    }
    
    // get audio file
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "getAudio" {
            
            let mergeVC = segue.destinationViewController as! FirstSceneViewController
            mergeVC.audioAsset = self.audioAssetToPass
            
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

//
//  VoiceOverViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/8/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class VoiceOverViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var videoPreviewLayer: UIView!
    
    var audioPlayer: AVAudioPlayer!
    let audioSession = AVAudioSession.sharedInstance()
    var videoPlayer: AVQueuePlayer!
    var playerLayer: AVPlayerLayer!
    var audioRecorder: AVAudioRecorder!
    var audioAssetToPass: NSURL!
    var progress: NSTimer!
    
    var sceneID: Int!
    var segueID = "sceneAudioSelectedSegue"
    var audioSaveID: String!
    var hasRecorded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // setup progress bar
        progressBar.alpha = 0
        progressBar.progress = 0
        // set up voice recorder
        AVAudioSession.sharedInstance().requestRecordPermission { (granted) -> Void in
            if granted {
                do {
                    try self.audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker)
                } catch let error as NSError {
                    print("audioSession error: \(error.localizedDescription)")
                }
                
                do {
                    try self.audioSession.setActive(true)
                } catch let activeError as NSError {
                    print(activeError.localizedDescription)
                }
            }
        }
        
        let url = MediaController.sharedMediaController.getVoiceOverSavePath("\(self.audioSaveID)")
        
        let recordSettings =
        [AVEncoderAudioQualityKey: AVAudioQuality.Min.rawValue,
            AVEncoderBitRateKey: 16,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0]
        
        do {
            try self.audioRecorder = AVAudioRecorder(URL: url, settings: recordSettings as! [String : AnyObject])
            audioRecorder!.prepareToRecord()
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }
        self.audioRecorder.delegate = self
    }
    
    
    override func viewWillLayoutSubviews() {
       self.previewScene()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        // set up initial button states
        playButton.enabled = false
        playButton.alpha = 0.4
        
        if self.videoPlayer?.currentItem != nil && self.videoPlayer.currentItem?.status == AVPlayerItemStatus.ReadyToPlay {
            
        recordButton.alpha = 1
        recordButton.enabled = true
        }
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        self.videoPlayer = nil
        self.audioPlayer = nil
        self.audioRecorder = nil
    }
    
    
    func updateProgress() {
        self.progressBar.progress += 0.001
    }
    
    
    @IBAction func recordButtonPressed(sender: AnyObject) {
        // set up progress view for recording time
        self.progressBar.alpha = 1
        self.progress = NSTimer.scheduledTimerWithTimeInterval(0.009, target: self, selector: "updateProgress", userInfo: nil, repeats: true)
        
        self.hasRecorded = true
        if self.audioPlayer?.playing == true {
            self.audioPlayer.stop()
        }
        if self.audioRecorder.recording == false {
            do {
                try self.audioSession.setActive(true)
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            
            recordButton.enabled = false
            recordButton.alpha = 0.5
            playButton.enabled = false
            playButton.alpha = 0.4
            doneButton.enabled = false
            doneButton.alpha = 0.4
            self.audioRecorder.recordForDuration(9.0)
            self.videoPlayer.play()
        }
    }
    
    
    @IBAction func playButtonPressed(sender: AnyObject) {
        if audioRecorder.recording == false {
            recordButton.enabled = false
            recordButton.alpha = 0.5
            playButton.alpha = 0.4
            playButton.enabled = false
            audioRecorder.stop()
            do {
                try self.audioPlayer = AVAudioPlayer(contentsOfURL: audioRecorder.url)
                self.audioPlayer.play()
            } catch let error as NSError {
                
                print("audioPlayer error: \(error.localizedDescription)")
            }
            self.audioPlayer.delegate = self
            self.videoPlayer.play()
        }
    }
    
    
    @IBAction func doneButtonPressed(sender: AnyObject) {
        self.audioRecorder.stop()
        do {
            try self.audioSession.setActive(false)
        } catch let audioSessionError as NSError {
            print(audioSessionError.localizedDescription)
        }
        
        print(audioRecorder.url.absoluteURL)
    
        if hasRecorded {
            self.audioAssetToPass = MediaController.sharedMediaController.getVoiceOverSavePath(self.audioSaveID)
        }
        
        self.performSegueWithIdentifier("sceneAudioSelectedSegue", sender: self)
    }
    
    // get audio file
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if self.audioAssetToPass != nil && segue.identifier ==  self.segueID {
            let sceneVC = segue.destinationViewController as! SceneViewController
            sceneVC.scene.voiceOver = self.audioAssetToPass.lastPathComponent!
            sceneVC.setupView()
        }
    }
    

    func previewScene() {
        var firstAsset: AVAsset!, secondAsset: AVAsset!, thirdAsset: AVAsset!
        
        firstAsset  = AVAsset(URL: MediaController.sharedMediaController.scenes[self.sceneID].shotVideos[0])
        secondAsset = AVAsset(URL: MediaController.sharedMediaController.scenes[self.sceneID].shotVideos[1])
        thirdAsset  = AVAsset(URL: MediaController.sharedMediaController.scenes[self.sceneID].shotVideos[2])
        
        
        if firstAsset != nil && secondAsset != nil && thirdAsset != nil {
            let assets = [firstAsset, secondAsset, thirdAsset]
            var shots = [AVPlayerItem]()

            for item in assets {
                let shot = AVPlayerItem(asset: item)
                shots.append(shot)
            }
            
            self.videoPlayer = AVQueuePlayer(items: shots)
            self.playerLayer = AVPlayerLayer(player: self.videoPlayer)
            self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "didFinishPlayingVideo:", name: AVPlayerItemDidPlayToEndTimeNotification, object: self.videoPlayer.items().last)
            self.videoPreviewLayer.layer.addSublayer(playerLayer)
            self.playerLayer.frame = self.videoPreviewLayer.bounds
        }
    }
    
    
    func didFinishPlayingVideo(notification: NSNotification) {
        self.progressBar.progress = 0.0
        self.progressBar.alpha = 0
        self.progress.invalidate()
        previewScene()
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
        recorder.stop()
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
}

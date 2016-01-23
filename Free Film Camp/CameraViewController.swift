//
//  CameraViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/6/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
//import MediaPlayer

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    // view components
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var clipsButton: UIButton!
    @IBOutlet weak var clipsView: UIImageView!
    @IBOutlet weak var confirmShotButton: UIButton!
    @IBOutlet weak var flipCameraButton: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var recordTimeButton: UIButton!
    @IBOutlet weak var rotateCameraToShoot: UIImageView!
    @IBOutlet var cameraView: UIView!
    // camera components
    let videoCapture = AVCaptureSession()
    
    var devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
    var camera: AVCaptureDevice!
    var selfieCam: AVCaptureDevice!
    
    let videoPreviewOutput = AVCaptureVideoDataOutput()
    let videoForFileOutput = AVCaptureMovieFileOutput()
    var preview: AVCaptureVideoPreviewLayer!
    var maxVideoTime = CMTime(seconds: 3, preferredTimescale: 1)
    var progress: NSTimer!
    
    // background queue
    var sessionQueue: dispatch_queue_t!
    var backgroundRecordingID: UIBackgroundTaskIdentifier!
    
    // video storage
    let toAlbumTitle = "Free Film Camp Clips"
    var newClip: PHObjectPlaceholder!
    var video: PHAsset!
    var shots: PHFetchResult!
    var shotAsset: AVURLAsset!
    var shotImage: UIImage!
    
    // logic variables
    var pickingShot = false
    var shotNumber: Int!
    var scene: String!
    var segueToPerform: String!
    var recorded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationChanged:", name: UIDeviceOrientationDidChangeNotification, object: UIDevice.currentDevice())
        self.rotateCameraToShoot.alpha = 0
        
        for device in self.devices {
            if device.hasMediaType(AVMediaTypeVideo) && device.position == AVCaptureDevicePosition.Front {
                self.selfieCam = device as! AVCaptureDevice
            } else if device.hasMediaType(AVMediaTypeVideo) && device.position == AVCaptureDevicePosition.Back {
                self.camera = device as! AVCaptureDevice
            }
        }
        
        do {
            try self.camera.lockForConfiguration()
        } catch let configError as NSError {
            print(configError.localizedDescription)
        }
        
        do {
            try self.selfieCam.lockForConfiguration()
        } catch let configError as NSError {
            print(configError.localizedDescription)
        }
        
        self.progressBar.alpha = 0
        self.progressBar.progress = 0
        self.navigationController?.navigationBarHidden = true
        // session setup
        videoCapture.sessionPreset = AVCaptureSessionPreset1280x720
        
        // queue setup
        sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)
        
        // add device as input to session.
        do {
            let input = try AVCaptureDeviceInput(device: self.camera)
            videoCapture.addInput(input)
        } catch let captureError as NSError {
            print(captureError.localizedDescription)
        }
        
        let microphone = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        var audioInput: AVCaptureDeviceInput!
        
        if self.segueToPerform != nil && self.segueToPerform == "introUnwind" {
            do {
                audioInput = try AVCaptureDeviceInput(device: microphone)
                videoCapture.addInput(audioInput)
            } catch let captureError as NSError {
                print(captureError.localizedDescription)
            }
        }
        
        videoCapture.addOutput(videoPreviewOutput)
        videoCapture.addOutput(videoForFileOutput)
        
        // setup preview for displaying what the camera sees
        preview = AVCaptureVideoPreviewLayer(session: videoCapture)
        self.cameraView.layer.addSublayer(preview)
        }
    
    
    override func viewWillLayoutSubviews() {
        self.preview.frame = self.view.bounds
        if preview.connection.supportsVideoOrientation {
            preview.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
        }
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        MediaController.sharedMediaController.albumTitle = MediaController.Albums.shots
        let videoCaptureOutput = self.videoForFileOutput.connectionWithMediaType(AVMediaTypeVideo)
        
        if videoCaptureOutput.supportsVideoStabilization {
            videoCaptureOutput.preferredVideoStabilizationMode = .Auto
        }
        videoCapture.startRunning()
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        self.pickingShot = false
        videoCapture.stopRunning()
        self.progress = nil
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIDeviceOrientationDidChangeNotification, object: UIDevice.currentDevice())
        if pickingShot {
            NSNotificationCenter.defaultCenter().postNotificationName(MediaController.Notifications.toolViewDismissed, object: self)
        }
    }
    
    
    func updateProgress() {
        self.progressBar.progress += 0.01
    }
    

    @IBAction func record(sender: AnyObject) {
        if camera.isFocusModeSupported(.Locked) {
            camera.focusMode = .Locked
        }
        videoForFileOutput.maxRecordedDuration = maxVideoTime
        // set up progress view for recording time
        self.progressBar.alpha = 1
        self.progress = NSTimer.scheduledTimerWithTimeInterval(0.03, target: self, selector: "updateProgress", userInfo: nil, repeats: true)
        // disable and hide buttons
        recordButton.alpha = 0
        recordButton.enabled = false
        flipCameraButton.alpha = 0
        flipCameraButton.userInteractionEnabled = false
        cancelButton.alpha = 0
        cancelButton.enabled = false
        
        // record for 3 seconds to file
        dispatch_async(self.sessionQueue) { () -> Void in
            if !self.videoForFileOutput.recording {
                // ensure that video will save even if user switches tasks.
                if UIDevice.currentDevice().multitaskingSupported {
                    self.backgroundRecordingID = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(nil)
                }
                
                // set orientation to match preview layer.
                let videoCaptureOutputConnection = self.videoForFileOutput.connectionWithMediaType(AVMediaTypeVideo)
                
                videoCaptureOutputConnection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
                
                var url: NSURL!
                
                // record to path.
                if self.segueToPerform != nil && self.segueToPerform == "introUnwind" {
                    url = MediaController.sharedMediaController.getIntroShotSavePath()
                } else {
                    url = self.getShotPath()
                }
                
                self.videoForFileOutput.startRecordingToOutputFileURL(url, recordingDelegate: self)
            } else {
                self.videoForFileOutput.stopRecording()
            }
        }
    }
    
    // MARK: Output recording delegate methods
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        
        print("Recording")
    }
    
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        // reset progress
        self.progressBar.progress = 0.0
        self.progressBar.alpha = 0
        self.progress.invalidate()
        if camera.isFocusModeSupported(.ContinuousAutoFocus) {
            camera.focusMode = .ContinuousAutoFocus
        }
        // prepare cleanup function to reset recording file for next recording
        let currentBackgroundRecordingID = self.backgroundRecordingID
        self.backgroundRecordingID = UIBackgroundTaskInvalid
        
        let cleanup: dispatch_block_t = { () -> Void in
            do {
                try NSFileManager.defaultManager().removeItemAtURL(outputFileURL)
            } catch let fileError as NSError {
                print(fileError.localizedDescription)
            }
            
            if currentBackgroundRecordingID != UIBackgroundTaskInvalid {
                UIApplication.sharedApplication().endBackgroundTask(currentBackgroundRecordingID)
            }
        }
        
        // handle success or failure of previous recording
        var success = true
        if (error != nil) {
            print("Did Finish Recording:",error.localizedDescription)
            success = error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as! Bool
        }
        
        // save file to Photos.
        if success && self.segueToPerform != "introUnwind" {
            // check if authorized to save to photos
            PHPhotoLibrary.requestAuthorization({ (status:PHAuthorizationStatus) -> Void in
                if status == PHAuthorizationStatus.Authorized {
                    // move movie to Photos library
                    PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                        let options = PHAssetResourceCreationOptions()
                        options.shouldMoveFile = true
                        let photosChangeRequest = PHAssetCreationRequest.creationRequestForAsset()
                        photosChangeRequest.addResourceWithType(PHAssetResourceType.Video, fileURL: outputFileURL, options: options)
                        self.newClip = photosChangeRequest.placeholderForCreatedAsset
                        }, completionHandler: { (success: Bool, error: NSError?) -> Void in
                            if !success {
                                print("Failed to save to photos: %@", error?.localizedDescription)
                                cleanup()
                            }
                    })
                    
                    // save movie to correct album
                    PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                        
                        // add to Free Film Camp album
                        let fetchOptions = PHFetchOptions()
                        fetchOptions.predicate = NSPredicate(format: "title = %@", self.toAlbumTitle)
                        let album: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
                        let albumCollection = album.firstObject as! PHAssetCollection
                        let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: albumCollection, assets: album)
                        albumChangeRequest?.addAssets([self.newClip])
                        self.shots = album
                        }, completionHandler: { (success: Bool, error: NSError?) -> Void in
                            if !success {
                                print("Failed to add photo to album: %@", error?.localizedDescription)
                            }
                    })
                } else {
                    cleanup()
                }
            })
        } else if success {
            // Access stored intro.
            let videoPath = MediaController.sharedMediaController.getIntroShotSavePath()
            
            if NSFileManager.defaultManager().fileExistsAtPath(videoPath.path!) {
                // print("IntroFILE!!!!!!!!!!!!!!!!\(videoPath)")
            } else {
                // print("IntroFUCK!!!!!!!!!!!\(videoPath)")
            }
            MediaController.sharedMediaController.intro = Intro(video: videoPath.lastPathComponent, image: nil)
            MediaController.sharedMediaController.saveIntro()
        }
        
        // re-enable camera button for new recording
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.recordButton.enabled = true
            self.recordButton.alpha = 1
            self.cancelButton.alpha = 1
            self.cancelButton.enabled = true
        }
        self.recorded = true
        print("End recording")
    }
    
    // MARK: Action methods
    @IBAction func cancelCamera(sender: AnyObject) {
        if self.pickingShot && self.shots != nil {
            let shotFetch = PHAsset.fetchAssetsInAssetCollection(self.shots.firstObject as! PHAssetCollection, options: nil)
            self.video = shotFetch.firstObject as! PHAsset
            let manager = PHImageManager()
            manager.requestImageForAsset(self.video,
                targetSize: CGSize(width: 215, height: 136),
                contentMode: .AspectFill,
                options: nil) { (result, _) -> Void in
                    self.shotImage = result!
            }
            manager.requestAVAssetForVideo(self.video, options: nil) { (videoAsset, audioMix, info) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if (videoAsset?.isKindOfClass(AVURLAsset) != nil) {
                        let url = videoAsset as! AVURLAsset
                        self.shotAsset = url
                        self.performSegueWithIdentifier(self.segueToPerform, sender: self)
                    }
                })
            }
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    
    @IBAction func flipCamera(sender: AnyObject) {
        self.videoCapture.beginConfiguration()
        
        let currentVideoDevice = self.videoCapture.inputs.first as! AVCaptureDeviceInput
        
        for device in self.videoCapture.inputs {
            self.videoCapture.removeInput(device as! AVCaptureInput)
        }
        
        var newDevice: AVCaptureDevice!
        let microphone = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
        
        var videoInput: AVCaptureDeviceInput!
        var audioInput: AVCaptureDeviceInput!
        
        if currentVideoDevice.device.position == AVCaptureDevicePosition.Back {
            newDevice = self.selfieCam
        } else if currentVideoDevice.device.position == AVCaptureDevicePosition.Front {
            newDevice = self.camera
        }
        
        do {
            videoInput = try AVCaptureDeviceInput(device: newDevice)
            
        } catch let captureError as NSError {
            print(captureError.localizedDescription)
        }
        videoCapture.addInput(videoInput)
        
        if self.segueToPerform != nil && self.segueToPerform == "introUnwind" {
            
            do {
                audioInput = try AVCaptureDeviceInput(device: microphone)
                
            } catch let captureError as NSError {
                print(captureError.localizedDescription)
            }
            videoCapture.addInput(audioInput)
        }
        self.videoCapture.commitConfiguration()
    }
    
    @IBAction func recordTime(sender: AnyObject) {
        
        
        
    }
    
    func orientationChanged(notificaton: NSNotification) {
        let device: UIDevice = notificaton.object as! UIDevice
        
        switch(device.orientation) {
        case UIDeviceOrientation.Portrait:
            self.rotateCameraToShoot.alpha = 1
            self.recordButton.enabled = false
            break
        case UIDeviceOrientation.PortraitUpsideDown:
            self.rotateCameraToShoot.alpha = 1
            self.recordButton.enabled = false
            break
        case UIDeviceOrientation.LandscapeLeft:
            self.rotateCameraToShoot.alpha = 0
            self.recordButton.enabled = true
            break
        case UIDeviceOrientation.LandscapeRight:
            self.rotateCameraToShoot.alpha = 1
            self.recordButton.enabled = false
            break
        case UIDeviceOrientation.Unknown:
            print("WTF!!")
            break
        default:
            break
        }
    }
    
    // MARK: Segue methods
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "cameraUnwindSegue" {
            let videosVC = segue.destinationViewController as! VideosViewController
            if self.shotAsset != nil && self.shotAsset != nil {
            videosVC.videoAssetToPass = self.shotAsset.URL
            videosVC.videoImageToPass = self.shotImage
            }
        } else if segue.identifier == "introUnwind" {
            let introVC = segue.destinationViewController as! IntroViewController
            introVC.getIntro()        }
    }
    
    // MARK: Path for shots going to photos framework
    func getShotPath() -> NSURL {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .FullStyle
        let date = dateFormatter.stringFromDate(NSDate())
        let videoOutputFilePath = NSTemporaryDirectory()
        let url = NSURL(fileURLWithPath: videoOutputFilePath).URLByAppendingPathComponent("mergeVideo-\(date).mov")
        return url
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

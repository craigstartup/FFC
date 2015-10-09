//
//  CameraViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/6/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
//import MediaPlayer

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    // view components
    @IBOutlet var cameraView: UIView!
    @IBOutlet weak var flipCameraButton: UIButton!
    @IBOutlet weak var recordTimeButton: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var clipsView: UIImageView!
    @IBOutlet weak var clipsButton: UIButton!
    
    // camera components
    let videoCapture = AVCaptureSession()
    let camera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    let videoPreviewOutput = AVCaptureVideoDataOutput()
    let videoForFileOutput = AVCaptureMovieFileOutput()
    var preview: AVCaptureVideoPreviewLayer!
    var maxVideoTime = CMTime(seconds: 3, preferredTimescale: 1)
    let progress = NSTimer()
    // background queue
    var sessionQueue: dispatch_queue_t!
    var backgroundRecordingID: UIBackgroundTaskIdentifier!
    // storage
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    let fetchOptions = PHFetchOptions()
    let toAlbumTitle = "Free Film Camp Clips"
    var newClip: PHObjectPlaceholder!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBarHidden = true
        // session setup
        videoCapture.sessionPreset = AVCaptureSessionPreset1280x720
        // queue setup
        sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)
        // add device as input to session.
        do {
            
            let input = try AVCaptureDeviceInput(device: camera)
            videoCapture.addInput(input)
            
        } catch let captureError as NSError {
            
            print(captureError.localizedDescription)
            
        }
        videoCapture.addOutput(videoPreviewOutput)
        videoCapture.addOutput(videoForFileOutput)
        // setup preview for displaying what the camera sees
        preview = AVCaptureVideoPreviewLayer(session: videoCapture)
        self.cameraView.layer.addSublayer(preview)
        // set up album for recorded clips
        fetchOptions.predicate = NSPredicate(format: "title = %@", toAlbumTitle)
        let toAlbum = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        
        if let _: AnyObject = toAlbum.firstObject {
            
            print("Free Film Camp Clips exists")
        } else {
            
            library.performChanges({ () -> Void in
                PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(toAlbumTitle)
                }) { (success: Bool, error: NSError?) -> Void in
                    if !success {
                        print(error!.localizedDescription)
                    }
            }
            
        }
        // setup progress bar 
        
    }
    
    
    override func viewWillLayoutSubviews() {
        
        self.preview.frame = self.view.bounds
        preview.videoGravity = AVLayerVideoGravityResizeAspectFill
        if preview.connection.supportsVideoOrientation {
            
            preview.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
            
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        videoCapture.startRunning()
    }
    
    
    override func viewDidDisappear(animated: Bool) {
        
        videoCapture.stopRunning()
    }
    

    @IBAction func record(sender: AnyObject) {
        
        videoForFileOutput.maxRecordedDuration = maxVideoTime
        self.tabBarController!.tabBar.alpha = 0
        self.tabBarController!.tabBar.userInteractionEnabled = false
        // disable and hide buttons
        recordButton.alpha = 0
        recordButton.enabled = false
        recordTimeButton.alpha = 0
        recordTimeButton.userInteractionEnabled = false
        flipCameraButton.alpha = 0
        flipCameraButton.userInteractionEnabled = false
        clipsView.alpha = 0
        clipsView.userInteractionEnabled = false
       
        
        // record for 3 seconds to file
        dispatch_async(self.sessionQueue) { () -> Void in
            
            if !self.videoForFileOutput.recording {
                // ensure that video will save even if user switches tasks.
                if UIDevice.currentDevice().multitaskingSupported {
                    
                    self.backgroundRecordingID = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(nil)
                }
                // set orientation to match preview layer.
                let videoCaptureOutputConnection = self.videoForFileOutput.connectionWithMediaType(AVMediaTypeVideo)
                videoCaptureOutputConnection.videoOrientation = self.preview.connection.videoOrientation
                // record to a temporary file.
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateStyle = .LongStyle
                dateFormatter.timeStyle = .ShortStyle
                let date = dateFormatter.stringFromDate(NSDate())
                let videoOutputFilePath = NSTemporaryDirectory()
                let url = NSURL(fileURLWithPath: videoOutputFilePath).URLByAppendingPathComponent("mergeVideo-\(date).mov")
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
        if success {
            
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
                            }
                            
                            cleanup()
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
                        
                        }, completionHandler: { (success: Bool, error: NSError?) -> Void in
                            
                            if !success {
                                
                                print("Failed to add photo to album: %@", error?.localizedDescription)
                            }
                            
                            cleanup()
                    })
                    
                } else {
                    
                    cleanup()
                }
            })
        } else {
            
            cleanup()
        }
        
        // re-enable camera button for new recording
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            self.recordButton.enabled = true
            self.recordButton.alpha = 1
            self.tabBarController!.tabBar.alpha = 1
            self.tabBarController!.tabBar.userInteractionEnabled = true
        }
        
        print("End recording")
    }
    
    
    @IBAction func flipCamera(sender: AnyObject) {
        
        
        
    }
    
    
    @IBAction func recordTime(sender: AnyObject) {
        
        
        
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

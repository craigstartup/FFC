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

class CameraViewController: UIViewController {
    
    // view components
    @IBOutlet var cameraView: UIView!
    @IBOutlet weak var flipCameraButton: UIButton!
    @IBOutlet weak var recordTimeButton: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var clipsView: UIImageView!
    
    // camera components
    let videoCapture = AVCaptureSession()
    let camera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    let videoPreviewOutput = AVCaptureVideoDataOutput()
    let videoForFileOutput = AVCaptureMovieFileOutput()
    var preview: AVCaptureVideoPreviewLayer!
    // background queue
    var sessionQueue: dispatch_queue_t!
    
    // storage
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    let fetchOptions = PHFetchOptions()
    let toAlbumTitle = "Free Film Camp Clips"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        // setup preview for displaying what the camera sees
        preview = AVCaptureVideoPreviewLayer(session: videoCapture)
        self.cameraView.layer.addSublayer(preview)
        // set up album for recorded clips
        fetchOptions.predicate = NSPredicate(format: "title = %@", toAlbumTitle)
        let toAlbum = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        
        if let _: AnyObject = toAlbum.firstObject {
            
            print("Free Film Camp Scenes exists")
        } else {
            
            library.performChanges({ () -> Void in
                PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(toAlbumTitle)
                }) { (success: Bool, error: NSError?) -> Void in
                    if !success {
                        print(error!.localizedDescription)
                    }
            }
            
        }

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

    @IBAction func record(sender: AnyObject) {
        
        
        
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

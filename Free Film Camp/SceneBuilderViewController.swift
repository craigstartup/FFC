//  Assisted by http://www.raywenderlich.com/94404/play-record-merge-videos-ios-swift
//  SceneBuilderViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/5/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit
import Photos
import AVFoundation


class SceneBuilderViewController: UIViewController {

    
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    let fetchOptions = PHFetchOptions()
    let toAlbumTitle = "Free Film Camp Scenes"
    var assetRequestNumber: Int!
    
    var selectedVideoAsset: NSURL!
    var firstAsset: AVAsset!
    var secondAsset: AVAsset!
    var thirdAsset: AVAsset!
    var audioAsset: AVAsset!
    var newScene: PHObjectPlaceholder!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set up album for recorded scenes
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

    @IBAction func selectClipOne(sender: AnyObject) {
        
        self.assetRequestNumber = 1
        self.performSegueWithIdentifier("clipsLibrary", sender: self)
        
    }
    
    @IBAction func selectClipTwo(sender: AnyObject) {
        
        self.assetRequestNumber = 2
        self.performSegueWithIdentifier("clipsLibrary", sender: self)
    }
    
    @IBAction func selectClip3(sender: AnyObject) {
        
        self.assetRequestNumber = 3
        self.performSegueWithIdentifier("clipsLibrary", sender: self)
    }
    
    @IBAction func record(sender: AnyObject) {
    }
    
    
    @IBAction func mergeMedia(sender: AnyObject) {
        
        if firstAsset != nil && secondAsset != nil && thirdAsset != nil {
            
            // set up container to hold media tracks.
            let mixComposition = AVMutableComposition()
            // track times
            let track1to2Time = CMTimeAdd(firstAsset.duration, secondAsset.duration)
            let totalTime = CMTimeAdd(track1to2Time, thirdAsset.duration)
            // create separate video tracks for individual adjustments before merge
            let firstTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                
                try firstTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, firstAsset.duration),
                    ofTrack: firstAsset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                    atTime: kCMTimeZero)
            } catch let firstTrackError as NSError {
                
                print(firstTrackError.localizedDescription)
            }
            
            let secondTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                
                try secondTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, secondAsset.duration),
                    ofTrack: secondAsset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                    atTime: firstAsset.duration)
            } catch let secondTrackError as NSError {
                
                print(secondTrackError.localizedDescription)
            }
            
            let thirdTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                
                try thirdTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, thirdAsset.duration),
                    ofTrack: thirdAsset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                    atTime: track1to2Time)
                
            } catch let thirdTrackError as NSError {
                
                print(thirdTrackError.localizedDescription)
            }
            
            // Set up an overall instructions array
            let mainInstruction = AVMutableVideoCompositionInstruction()
            mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalTime)
            
            // Create seperate instructions for each track with helper method to correct orientation.
            let firstInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: firstTrack)
            // Make sure each track becomes transparent at end for the next one to play.
            firstInstruction.setOpacity(0.0, atTime: firstAsset.duration)
            let secondInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: secondTrack)
            secondInstruction.setOpacity(0.0, atTime: track1to2Time)
            let thirdInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: thirdTrack)
            // Add individual instructions to main for execution.
            mainInstruction.layerInstructions = [firstInstruction, secondInstruction, thirdInstruction]
            let mainComposition = AVMutableVideoComposition()
            // Add instruction composition to main composition and set frame rate to 30 per second.
            mainComposition.instructions = [mainInstruction]
            mainComposition.frameDuration = CMTimeMake(1, 30)
            mainComposition.renderSize = mixComposition.naturalSize
            // get audio
            if audioAsset != nil {
                
                let audioTrack: AVMutableCompositionTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: 0)
                
                do {
                    
                    try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, totalTime), ofTrack: audioAsset.tracksWithMediaType(AVMediaTypeAudio)[0] ,
                        atTime: kCMTimeZero)
                    
                } catch let audioTrackError as NSError{
                    
                    print(audioTrackError.localizedDescription)
                }
            }
            // get path
            let paths: NSArray = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            
            let documentDirectory: String = paths[0] as! String
            let id = String(arc4random() % 1000)
            let url = NSURL(fileURLWithPath: documentDirectory).URLByAppendingPathComponent("mergeVideo-\(id).mov")
            // make exporter
            let exporter = AVAssetExportSession(
                asset: mixComposition,
                presetName: AVAssetExportPresetHighestQuality)
            exporter!.outputURL = url
            exporter!.outputFileType = AVFileTypeQuickTimeMovie
            exporter!.shouldOptimizeForNetworkUse = true
            exporter!.videoComposition = mainComposition
            exporter!
                .exportAsynchronouslyWithCompletionHandler() {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.exportDidFinish(exporter!)
                    })
            }
        }
        
    }
    
    // MARK: unwind segues
    @IBAction func clipUnwindSegue(unwindSegue: UIStoryboardSegue) {
        
        if assetRequestNumber == 1 {
            
            self.firstAsset = AVAsset(URL: self.selectedVideoAsset)
        } else if assetRequestNumber == 2 {
            
            self.secondAsset = AVAsset(URL: self.selectedVideoAsset)
        } else if assetRequestNumber == 3 {
            
            self.thirdAsset = AVAsset(URL: self.selectedVideoAsset)
        }
    }
    
    @IBAction func audioUnwindSegue(unwindSegue: UIStoryboardSegue){
        
    }
    
    // MARK: Merge Helper Methods
    func exportDidFinish(session:AVAssetExportSession) {
        
        assert(session.status == AVAssetExportSessionStatus.Completed, "Session status not completed")
        
        
        if session.status == AVAssetExportSessionStatus.Completed {
            
            let outputURL: NSURL = session.outputURL!
            
            let cleanup: dispatch_block_t = { () -> Void in
                
                do {
                    
                    try NSFileManager.defaultManager().removeItemAtURL(outputURL)
                } catch let fileError as NSError {
                    
                    print(fileError.localizedDescription)
                }
            }

            // check if authorized to save to photos
            PHPhotoLibrary.requestAuthorization({ (status:PHAuthorizationStatus) -> Void in
                
                if status == PHAuthorizationStatus.Authorized {
                    
                    // move movie to Photos library
                    PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                        
                        let options = PHAssetResourceCreationOptions()
                        options.shouldMoveFile = true
                        let photosChangeRequest = PHAssetCreationRequest.creationRequestForAsset()
                        photosChangeRequest.addResourceWithType(PHAssetResourceType.Video, fileURL: outputURL, options: options)
                        self.newScene = photosChangeRequest.placeholderForCreatedAsset
                        
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
                        albumChangeRequest?.addAssets([self.newScene])
                        
                        }, completionHandler: { (success: Bool, error: NSError?) -> Void in
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                
                                if !success {
                                    
                                    
                                    let alert = UIAlertController(title: "Failed", message: "Failed to save video", preferredStyle: .Alert)
                                    let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
                                    alert.addAction(action)
                                    self.presentViewController(alert, animated: true, completion: nil)
                                    print("Failed to add photo to album: %@", error?.localizedDescription)
                                } else {
                                    
                                    let alert = UIAlertController(title: "Success", message: "Video saved.", preferredStyle: .Alert)
                                    let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
                                    alert.addAction(action)
                                    self.presentViewController(alert, animated: true, completion: nil)
                                    
                                    
                                }
                            })
                            cleanup()
                    })
                    
                } else {
                    
                    cleanup()
                }
            })
        }
        audioAsset = nil
        firstAsset = nil
        secondAsset = nil
        thirdAsset = nil
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

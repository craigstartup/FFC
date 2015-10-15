//
//  MediaLibraryController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/13/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import Foundation
import Photos
import AVFoundation

class MediaController {
    
    static let sharedMediaController = MediaController()
    
    let library = PHPhotoLibrary.sharedPhotoLibrary()

    // Shots
    var s1Shot1: AVAsset!
    var s1Shot2: AVAsset!
    var s1Shot3: AVAsset!
    var s1VoiceOver: AVAsset!

    var s2Shot1: AVAsset!
    var s2Shot2: AVAsset!
    var s2Shot3: AVAsset!
    var s2VoiceOver: AVAsset!

    var s3Shot1: AVAsset!
    var s3Shot2: AVAsset!
    var s3Shot3: AVAsset!
    var s3VoiceOver: AVAsset!

    // place holder for scene
    var newScene: PHObjectPlaceholder!
    
    //Scenes
    var scene1: AVAsset!
    var scene2: AVAsset!
    var scene3: AVAsset!
    
    let clipsAlbumTitle = "Free Film Camp Clips"
    let scenesAlbumTitle = "Free Film Camp Scenes"
    let moviesAlbumTitle = "Free Film Camp Movies"
    
    var saveSceneSuccess = false
    
    
    func saveScene(scene: Int) -> Bool {
        
        var firstAsset: AVAsset!, secondAsset: AVAsset!, thirdAsset: AVAsset!, audioAsset: AVAsset!
        
        switch (scene) {
            
        case 1:
            firstAsset = self.s1Shot1
            secondAsset = self.s1Shot2
            thirdAsset  = self.s1Shot3
            audioAsset = self.s1VoiceOver
        case 2:
            firstAsset = self.s2Shot1
            secondAsset = self.s2Shot2
            thirdAsset  = self.s2Shot3
            audioAsset = self.s2VoiceOver
        case 3:
            firstAsset = self.s3Shot1
            secondAsset = self.s3Shot2
            thirdAsset  = self.s3Shot3
            audioAsset = self.s3VoiceOver
        default:
            print("Invalid scene number")
        }
        
        
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
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .LongStyle
            dateFormatter.timeStyle = .ShortStyle
            let date = dateFormatter.stringFromDate(NSDate())
            let url = NSURL(fileURLWithPath: documentDirectory).URLByAppendingPathComponent("mergeVideo-\(date).mov")
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
        return self.saveSceneSuccess
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
                    
                    // move scene to Photos library
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
                        fetchOptions.predicate = NSPredicate(format: "title = %@", self.scenesAlbumTitle)
                        let album: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
                        let albumCollection = album.firstObject as! PHAssetCollection
                        let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: albumCollection, assets: album)
                        albumChangeRequest?.addAssets([self.newScene])
                        
                        }, completionHandler: { (success: Bool, error: NSError?) -> Void in
                                
                                if !success {
                                    
                                    self.saveSceneSuccess = false
                                    print("Failed to add photo to album: %@", error?.localizedDescription)
                                } else {
                                    
                                    self.saveSceneSuccess = true
                                }
                            cleanup()
                    })
                    
                } else {
                    
                    cleanup()
                }
            })
        }
    }
}
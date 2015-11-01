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
import AVKit

class MediaController {
    
    enum Notifications {
        
        static let audioExportStart  = "audioExportBegan"
        static let audioExportFinish = "audioExportComplete"
        static let saveSceneFinished = "saveSceneComplete"
        static let saveSceneFailed   = "saveMovieFailed"
        static let saveMovieFinished = "saveMovieComplete"
        static let saveMovieFailed   = "saveMovieFailed"
        
    }
    
    static let sharedMediaController = MediaController()
    private init() {}
    
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    let comCenter = NSNotificationCenter.defaultCenter()
    // Main voiceover
    var audioVoiceOverAsset: AVAsset!
    var sessionURL: NSURL!
    var vOExporter: AVAssetExportSession!
    // Scene components
    var s1Shot1: AVAsset!
    var s1Shot1Image: UIImage!
    var s1Shot2: AVAsset!
    var s1Shot2Image: UIImage!
    var s1Shot3: AVAsset!
    var s1Shot3Image: UIImage!
    var s1VoiceOver: AVAsset!
    
    var s2Shot1: AVAsset!
    var s2Shot1Image: UIImage!
    var s2Shot2: AVAsset!
    var s2Shot2Image: UIImage!
    var s2Shot3: AVAsset!
    var s2Shot3Image: UIImage!
    var s2VoiceOver: AVAsset!
    
    var s3Shot1: AVAsset!
    var s3Shot1Image: UIImage!
    var s3Shot2: AVAsset!
    var s3Shot2Image: UIImage!
    var s3Shot3: AVAsset!
    var s3Shot3Image:UIImage!
    var s3VoiceOver: AVAsset!
    
    // movie
    var moviePreview: AVPlayerItem!

    // place holder for scene
    var newScene: PHObjectPlaceholder!
    
    //Scenes
    var scene1: AVAsset!
    var scene2: AVAsset!
    var scene3: AVAsset!
    
    var albumTitle = "Free Film Camp Clips"
    
    func saveScene(scene: Int) {
        var firstAsset: AVAsset!, secondAsset: AVAsset!, thirdAsset: AVAsset!, audioAsset: AVAsset!
        
        self.albumTitle = "Free Film Camp Scenes"
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
            let sceneComposition = AVMutableComposition()
            // track times
            let track1to2Time = CMTimeAdd(firstAsset.duration, secondAsset.duration)
            let totalTime = CMTimeAdd(track1to2Time, thirdAsset.duration)
            // create separate video tracks for individual adjustments before merge
            let firstTrack = sceneComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                try firstTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, firstAsset.duration),
                    ofTrack: firstAsset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                    atTime: kCMTimeZero)
            } catch let firstTrackError as NSError {
                print(firstTrackError.localizedDescription)
            }
            
            let secondTrack = sceneComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                try secondTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, secondAsset.duration),
                    ofTrack: secondAsset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                    atTime: firstAsset.duration)
            } catch let secondTrackError as NSError {
                print(secondTrackError.localizedDescription)
            }
            
            let thirdTrack = sceneComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
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
            let mainSceneComposition = AVMutableVideoComposition()
            // Add instruction composition to main composition and set frame rate to 30 per second.
            mainSceneComposition.instructions = [mainInstruction]
            mainSceneComposition.frameDuration = CMTimeMake(1, 30)
            mainSceneComposition.renderSize = sceneComposition.naturalSize
            // get audio
            if audioAsset != nil {
                let audioTrack: AVMutableCompositionTrack = sceneComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: 0)
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
            dateFormatter.timeStyle = .LongStyle
            let date = dateFormatter.stringFromDate(NSDate())
            let url = NSURL(fileURLWithPath: documentDirectory).URLByAppendingPathComponent("mergeVideo-\(date).mov")
            // make exporter
            let exporter = AVAssetExportSession(
                asset: sceneComposition,
                presetName: AVAssetExportPresetHighestQuality)
            exporter!.outputURL = url
            exporter!.outputFileType = AVFileTypeQuickTimeMovie
            exporter!.videoComposition = mainSceneComposition
            exporter!
                .exportAsynchronouslyWithCompletionHandler() {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.exportDidFinish(exporter!, type: "scene")
                    })
            }
        }
    }
    
    
    func prepareMovie(save: Bool) {
        albumTitle = "Free Film Camp Movies"
        if self.s1Shot1 != nil && s1Shot2 != nil && s1Shot3 != nil &&
        self.s2Shot1 != nil && s2Shot2 != nil && s2Shot3 != nil &&
        self.s3Shot1 != nil && s3Shot2 != nil && s3Shot3 != nil {
            defer {
                self.moviePreview = nil
            }
            let bumper = AVAsset(URL: NSBundle.mainBundle().URLForResource("Bumper_3 sec", withExtension: "mp4")!)
            var mixComposition = AVMutableComposition()
            let assets = [self.s1Shot1, self.s1Shot2, self.s1Shot3, self.s2Shot1, self.s2Shot2, self.s2Shot3, self.s3Shot1, self.s3Shot2, self.s3Shot3, bumper]
            
            if self.s1VoiceOver != nil && self.s2VoiceOver != nil && self.s3VoiceOver != nil {
                let voiceOvers = [self.s1VoiceOver, self.s2VoiceOver, self.s3VoiceOver]
                let audioComposition = AVMutableComposition()
                var audioTrackTime = kCMTimeZero
                
                for var y = 0; y < voiceOvers.count; y++ {
                    let audioTrack = audioComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
                    do {
                        try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, voiceOvers[y].duration), ofTrack: voiceOvers[y].tracksWithMediaType(AVMediaTypeAudio)[0],
                            atTime: audioTrackTime)
                    } catch let audioTrackError as NSError {
                        print(audioTrackError.localizedDescription)
                    }
                    audioTrackTime = CMTimeAdd(audioTrackTime, voiceOvers[y].duration)
                }
                // get path
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateStyle = .LongStyle
                dateFormatter.timeStyle = .LongStyle
                let date = dateFormatter.stringFromDate(NSDate())
                let vOFilePath = NSTemporaryDirectory()
                let url = NSURL(fileURLWithPath: vOFilePath).URLByAppendingPathComponent("vo-\(date).m4a")
                // make exporter
                vOExporter = AVAssetExportSession(
                    asset: audioComposition,
                    presetName: AVAssetExportPresetAppleM4A)
                vOExporter!.outputURL = url
                vOExporter!.outputFileType = AVFileTypeAppleM4A
                vOExporter!.shouldOptimizeForNetworkUse = true
                vOExporter!
                    .exportAsynchronouslyWithCompletionHandler() {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            if self.vOExporter.status == AVAssetExportSessionStatus.Completed {
                                print("Export finished")
                                self.sessionURL = self.vOExporter.outputURL!
                                self.finishMovie(&mixComposition, assets: assets, save: save)
                            } else if self.vOExporter.status == AVAssetExportSessionStatus.Waiting {
                                print("Export waiting")
                            } else if self.vOExporter.status == AVAssetExportSessionStatus.Failed {
                                print("Export failure")
                            }
                        })
                }
            } else {
                self.finishMovie(&mixComposition, assets: assets, save: save)
            }
        }
    }
    
    
    func finishMovie(inout mixComposition: AVMutableComposition, assets: [AVAsset!], save: Bool) {
        let cleanup: dispatch_block_t = { () -> Void in
            do {
                try NSFileManager.defaultManager().removeItemAtURL(self.vOExporter.outputURL!)
            } catch let fileError as NSError {
                
                print(fileError.localizedDescription)
            }
        }

        var totalTime: CMTime = kCMTimeZero
        
        for var x = 0; x < assets.count; x++ {
            totalTime = CMTimeAdd(totalTime, assets[x].duration)
        }
        
        // create tracks with sequential starting times.
        var tracks = [AVMutableCompositionTrack]()
        var tracksTime: CMTime = kCMTimeZero
        for var i = 0; i < assets.count; i++ {
            let track = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            do {
                try track.insertTimeRange(CMTimeRangeMake(kCMTimeZero, assets[i].duration),
                    ofTrack: assets[i].tracksWithMediaType(AVMediaTypeVideo)[0] ,
                    atTime: tracksTime)
            } catch let firstTrackError as NSError {
                print(firstTrackError.localizedDescription)
            }
            tracksTime = CMTimeAdd(tracksTime, assets[i].duration)
            tracks.append(track)
        }
        
        // Set up an overall instructions array to manage video visibility.
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalTime)
        var instructions = [AVMutableVideoCompositionLayerInstruction]()
        var instructionTime: CMTime = kCMTimeZero
        // Create seperate instructions for each track.
        for var i = 0; i < tracks.count; i++ {
            let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: tracks[i])
            instructionTime = CMTimeAdd(instructionTime, assets[i].duration)
            instruction.setOpacity(0.0, atTime: instructionTime)
            instructions.append(instruction)
        }
        
        // Add individual instructions to main for execution.
        mainInstruction.layerInstructions = instructions
        let mainComposition = AVMutableVideoComposition()
        // Add instruction composition to main composition and set frame rate to 30 per second.
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(1, 30)
        mainComposition.renderSize = mixComposition.naturalSize
        //let mix = AVMutableAudioMix()
        if self.sessionURL != nil {
            self.audioVoiceOverAsset = AVAsset(URL: self.sessionURL)
            let vOTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio,
                preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            do {
                try vOTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, totalTime),
                    ofTrack: self.audioVoiceOverAsset.tracksWithMediaType(AVMediaTypeAudio)[0] ,
                    atTime: kCMTimeZero)
            } catch let firstTrackError as NSError {
                print(firstTrackError.localizedDescription)
            }
        }
        
        self.moviePreview = AVPlayerItem(asset: mixComposition)
        self.moviePreview.videoComposition = mainComposition
        
        if save {
            // setup to save
            let paths: NSArray = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let documentDirectory: String = paths[0] as! String
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .LongStyle
            dateFormatter.timeStyle = .LongStyle
            let date = dateFormatter.stringFromDate(NSDate())
            let url = NSURL(fileURLWithPath: documentDirectory).URLByAppendingPathComponent("mergeVideo-\(date).mov")
            // make exporter
            let exporter = AVAssetExportSession(
                asset: mixComposition,
                presetName: AVAssetExportPresetHighestQuality)
            exporter!.outputURL = url
            exporter!.outputFileType = AVFileTypeQuickTimeMovie
            //exporter!.audioMix = mix
            exporter!.videoComposition = mainComposition
            exporter!
                .exportAsynchronouslyWithCompletionHandler() {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.exportDidFinish(exporter!, type: "movie")
                    })
            }
            self.s1Shot1 = nil
            self.s1Shot2 = nil
            self.s1Shot3 = nil
            self.s1Shot1Image = nil
            self.s1Shot2Image = nil
            self.s1Shot3Image = nil
            self.s1VoiceOver = nil
            self.s2Shot1 = nil
            self.s2Shot2 = nil
            self.s2Shot3 = nil
            self.s2Shot1Image = nil
            self.s2Shot2Image = nil
            self.s2Shot3Image = nil
            self.s2VoiceOver = nil
            self.s3Shot1 = nil
            self.s3Shot2 = nil
            self.s3Shot3 = nil
            self.s3Shot1Image = nil
            self.s3Shot2Image = nil
            self.s3Shot3Image = nil
            self.s3VoiceOver = nil
            if vOExporter != nil {
                cleanup()
            }
            self.audioVoiceOverAsset = nil
            self.vOExporter = nil
        }
    }
    
    // MARK: Merge Helper Methods
    func exportDidFinish(session:AVAssetExportSession, type: String) {
        if session.status == AVAssetExportSessionStatus.Completed {
            let outputURL: NSURL = session.outputURL!
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
                    })
                    
                    // save movie to correct album
                    PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                        // add to Free Film Camp album
                        let fetchOptions = PHFetchOptions()
                        fetchOptions.predicate = NSPredicate(format: "title = %@", self.albumTitle)
                        let album: PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
                        let albumCollection = album.firstObject as! PHAssetCollection
                        let albumChangeRequest = PHAssetCollectionChangeRequest(forAssetCollection: albumCollection, assets: album)
                        albumChangeRequest?.addAssets([self.newScene])
                        }, completionHandler: { (success: Bool, error: NSError?) -> Void in
                            if !success {
                                print("Failed to add photo to album: %@", error?.localizedDescription)
                            } else {
                                print("SUCCESS")
                            }
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                if type == "movie" {
                                    NSNotificationCenter.defaultCenter().postNotificationName(Notifications.saveMovieFinished, object: self)
                                } else if type == "scene" {
                                    NSNotificationCenter.defaultCenter().postNotificationName(Notifications.saveSceneFinished, object: self)
                                }
                            })
                    })
                }
            })
        } else {
            print("SESSION STATUS NOT COMPLETED")
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if type == "movie" {
                    NSNotificationCenter.defaultCenter().postNotificationName(Notifications.saveMovieFailed, object: self)
                } else if type == "scene" {
                    NSNotificationCenter.defaultCenter().postNotificationName(Notifications.saveSceneFailed, object: self)
                }
            })
        }
    }
}
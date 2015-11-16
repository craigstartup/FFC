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
        static let previewReady      = "previewPrepped"
        
    }
    
    static let sharedMediaController = MediaController()
    private init() {}
    
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    // Media components
    var scenes = [Scene]()
    var musicTrack: AVURLAsset!
    var preview: AVPlayerItem!
    // temp cleanup
    var tempPaths = [NSURL]()

    // place holder for scene
    var newScene: PHObjectPlaceholder!
    
    var albumTitle = "Free Film Camp Clips"
    
    // MARK: Media methods
    func prepareMedia(media: [Scene]?, movie: Bool, save: Bool) {
        // Exactract and assemble media assets
        var videoAssets = [AVURLAsset]()
        var voiceOverAssets = [AVURLAsset]()
        // TODO: Check assets and post notification for what is missing.
        for scene in media! {
            for video in scene.shotVideos {
                let videoAsset = AVURLAsset(URL: video)
                videoAssets.append(videoAsset)
            }
            
            let voiceOverAsset = AVURLAsset(URL: scene.voiceOver)
            voiceOverAssets.append(voiceOverAsset)
        }
        // If movie, prepare voiceover, prepend intro and append bumper to video array
        if movie {
            let bumper = AVURLAsset(URL: NSBundle.mainBundle().URLForResource("Bumper_3 sec", withExtension: "mp4")!)
            videoAssets.append(bumper)
            self.getMovieVoiceOver(voiceOverAssets, videoAssets: videoAssets, save: save)
        } else if !movie {
           self.preview = self.composeMedia(videoAssets, voiceOverAssets: voiceOverAssets, movieVoiceOver: nil, movie: movie, save: save)
        }
    }
    
    
    func composeMedia(videoAssets: [AVURLAsset], voiceOverAssets: [AVURLAsset], movieVoiceOver: AVURLAsset?, movie: Bool, save: Bool) -> AVPlayerItem? {
        // Compose assets into a scene or movie.
        let mixComposition = AVMutableComposition()
        var tracks = [AVMutableCompositionTrack]()
        var tracksTime: CMTime = kCMTimeZero
        
        // create instructions for each track
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, tracksTime)
        var instructions = [AVMutableVideoCompositionLayerInstruction]()
        var instructionTime: CMTime = kCMTimeZero
        
        // Video
        for videoAsset in videoAssets {
            // TODO: Handle assets with zero tracks. Post notifiction for composition failure.
            // create tracks for each video asset
            let track = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            do {
                try track.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration),
                    ofTrack: videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                    atTime: tracksTime)
            } catch let firstTrackError as NSError {
                print(firstTrackError.localizedDescription)
            }
            tracksTime = CMTimeAdd(tracksTime, videoAsset.duration)
            tracks.append(track)
            
            // creat instructions for each track
            let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            instructionTime = CMTimeAdd(instructionTime, videoAsset.duration)
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
        
        // process audio for each set of videos(scene) if present or not movie
        if movieVoiceOver == nil {
            for voiceOverAsset in voiceOverAssets {
                let audioTrack: AVMutableCompositionTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
                do { // TODO: Possibly adjust tracks time to be more comprehensive.
                    try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, tracksTime), ofTrack: voiceOverAsset.tracksWithMediaType(AVMediaTypeAudio)[0] ,
                        atTime: kCMTimeZero)
                } catch let audioTrackError as NSError{
                    print(audioTrackError.localizedDescription)
                }
            }
        } else {
            // add movie voiceover
            if movieVoiceOver != nil {
                let audioTrack: AVMutableCompositionTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
                do {
                    try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, tracksTime), ofTrack: movieVoiceOver!.tracksWithMediaType(AVMediaTypeAudio)[0] ,
                        atTime: kCMTimeZero)
                } catch let audioTrackError as NSError{
                    print(audioTrackError.localizedDescription)
                }
            }
            
            // add music track
            if self.musicTrack != nil {
                let mTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
                do {
                    try mTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, tracksTime), ofTrack: self.musicTrack.tracksWithMediaType(AVMediaTypeAudio)[0], atTime: kCMTimeZero)
                } catch let musicTrackError as NSError {
                    print(musicTrackError.localizedDescription)
                }
            }
        }
        
        
        if save {
            self.saveMedia(mixComposition, videoComposition: mainComposition, movie: movie)
            return nil
        } else {
            // return preview
            let preview = AVPlayerItem(asset: mixComposition)
            preview.videoComposition = mainComposition
            NSNotificationCenter.defaultCenter().postNotificationName(Notifications.previewReady, object: self)
            return preview
        }
    }
    
    // MARK: Movie methods
    func getMovieVoiceOver(voiceOvers: [AVURLAsset], videoAssets: [AVURLAsset], save: Bool) {
        let audioComposition = AVMutableComposition()
        var audioTrackTime = kCMTimeZero
        
        for voiceOver in voiceOvers {
            let audioTrack = audioComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            do {
                try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, voiceOver.duration), ofTrack: voiceOver.tracksWithMediaType(AVMediaTypeAudio)[0],
                    atTime: audioTrackTime)
            } catch let audioTrackError as NSError {
                print(audioTrackError.localizedDescription)
            }
            audioTrackTime = CMTimeAdd(audioTrackTime, voiceOver.duration)
        }
        // get path
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .LongStyle
        let date = dateFormatter.stringFromDate(NSDate())
        let vOFilePath = NSTemporaryDirectory()
        let url = NSURL(fileURLWithPath: vOFilePath).URLByAppendingPathComponent("vo-\(date).m4a")
        MediaController.sharedMediaController.tempPaths.append(url)
        // make exporter
        let vOExporter = AVAssetExportSession(
            asset: audioComposition,
            presetName: AVAssetExportPresetAppleM4A)
        vOExporter!.outputURL = url
        vOExporter!.outputFileType = AVFileTypeAppleM4A
        vOExporter!.shouldOptimizeForNetworkUse = true
        vOExporter!
            .exportAsynchronouslyWithCompletionHandler() {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    // TODO: Handle nil.
                    if vOExporter!.status == AVAssetExportSessionStatus.Completed {
                        print("Export finished")
                        let movieVoiceOver = AVURLAsset(URL: (vOExporter?.outputURL)!)
                        self.preview = self.composeMedia(videoAssets, voiceOverAssets: voiceOvers, movieVoiceOver: movieVoiceOver, movie: true, save: save)
                    } else if vOExporter!.status == AVAssetExportSessionStatus.Waiting {
                        print("Export waiting")
                    } else if vOExporter!.status == AVAssetExportSessionStatus.Failed {
                        print("Export failure")
                    }
                })
        }
    }
    
    
    // MARK: Media save methods
    func saveMedia(mixComposition: AVMutableComposition, videoComposition: AVMutableVideoComposition, movie: Bool) {
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
        exporter!.videoComposition = videoComposition
        exporter!
            .exportAsynchronouslyWithCompletionHandler() {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.exportDidFinish(exporter!, type: movie ? "movie" : "scene")
                })
        }
    }
    
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
                        } else if success {
                            self.destroyTemp()
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
    
    
    
    func destroyTemp() {
        for temp in self.tempPaths {
            let cleanup: dispatch_block_t = { () -> Void in
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(temp)
                } catch let fileError as NSError {
                    print(fileError.localizedDescription)
                }
            }
            cleanup()
        }
    }
    
    
    // MARK: NSCoding
    func saveScenes() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(scenes, toFile: Scene.ArchiveURL.path!)
        if !isSuccessfulSave {
            print("FAILED TO SAVE")
        }
    }
    
    func loadScenes() -> [Scene]?{
        return NSKeyedUnarchiver.unarchiveObjectWithFile(Scene.ArchiveURL.path!) as? [Scene]
    }
}
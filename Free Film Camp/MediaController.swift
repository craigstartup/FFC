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
import SwiftyDropbox

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
    
    enum Albums {
        static let shots = "Free Film Camp Clips"
        static let scenes = "Free Film Camp Scenes"
        static let movies = "Free Film Camp Movies"
    }
    
    static let sharedMediaController = MediaController()
    private init() {}
    
    var albumTitle: String!
    var project = NSUserDefaults.standardUserDefaults().stringForKey("currentProject")
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    
    // Media components
    var scenes: [Scene]!
    var intro: Intro!
    var musicTrack: AVURLAsset!
    var preview: AVPlayerItem!

    // place holder for scene
    var newScene: PHObjectPlaceholder!
    
    // MARK: Media methods
    func prepareMedia(intro: Bool, media: [Scene]!, movie: Bool, save: Bool) {
        // Exactract and assemble media assets
        var videoAssets = [AVURLAsset]()
        var voiceOverAssets = [AVURLAsset]()
        
        if intro && self.intro != nil {
            // Intro has audio and video tracks. Append it to both assets arrays.
            let introPath = self.getPathForFileInDocumentsDirectory(self.intro.video)
            let introVideo = AVURLAsset(URL: introPath)
            videoAssets.append(introVideo)
            voiceOverAssets.append(introVideo)
        }
        
        // TODO: Check assets and post notification for what is missing.
        if media != nil {
            for scene in media {
                for video in scene.shotVideos {
                    let videoAsset = AVURLAsset(URL: video)
                    
                    if !videoAsset.tracks.isEmpty {
                        videoAssets.append(videoAsset)
                    }
                }
                
                let voiceOverPath = self.getPathForFileInDocumentsDirectory(scene.voiceOver)
                let voiceOverAsset = AVURLAsset(URL: voiceOverPath)
                
                if !voiceOverAsset.tracks.isEmpty {
                    voiceOverAssets.append(voiceOverAsset)
                }
            }
        }
        
        // If movie, prepare voiceover, prepend intro and append bumper to video array
        if movie {
            let bumper = AVURLAsset(URL: NSBundle.mainBundle().URLForResource("Bumper_3 sec", withExtension: "mp4")!)
            videoAssets.append(bumper)
            if !voiceOverAssets[0].tracks.isEmpty {
                self.getMovieVoiceOver(voiceOverAssets, videoAssets: videoAssets, save: save)
            } else {
                self.composeMedia(videoAssets, voiceOverAssets: voiceOverAssets, movieVoiceOver: nil, movie: true, save: save)
            }
        } else if !movie {
            self.composeMedia(videoAssets, voiceOverAssets: voiceOverAssets, movieVoiceOver: nil, movie: movie, save: save)
        }
    }
    
    
    func getMovieVoiceOver(voiceOvers: [AVURLAsset], videoAssets: [AVURLAsset], save: Bool) {
        let audioComposition = AVMutableComposition()
        var audioTrackTime = kCMTimeZero
        print(voiceOvers.count)
        print(videoAssets.count)
        
        for voiceOver in voiceOvers {
            let audioTrack = audioComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            if !voiceOver.tracks.isEmpty {
                do {
                    try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, voiceOver.duration), ofTrack: voiceOver.tracksWithMediaType(AVMediaTypeAudio)[0],
                        atTime: audioTrackTime)
                } catch let audioTrackError as NSError {
                    print(audioTrackError.localizedDescription)
                }
                audioTrackTime = CMTimeAdd(audioTrackTime, voiceOver.duration)
            } else {
                print("voice over empty")
                
            }
        }
        // get path
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .FullStyle
        let date = dateFormatter.stringFromDate(NSDate())
        let vOFilePath = NSTemporaryDirectory()
        let url = NSURL(fileURLWithPath: vOFilePath).URLByAppendingPathComponent("vo-\(date).m4a")
        
        // make exporter
        let vOExporter = AVAssetExportSession(
            asset: audioComposition,
            presetName: AVAssetExportPresetAppleM4A)
        vOExporter!.outputURL = url
        vOExporter!.outputFileType = AVFileTypeAppleM4A
        vOExporter!.shouldOptimizeForNetworkUse = true
        vOExporter!
            .exportAsynchronouslyWithCompletionHandler() {
                    // TODO: Handle nil.
                    if vOExporter!.status == AVAssetExportSessionStatus.Completed {
                        print("Export finished")
                        let movieVoiceOver = AVURLAsset(URL: (vOExporter?.outputURL)!)
                        self.composeMedia(videoAssets, voiceOverAssets: voiceOvers, movieVoiceOver: movieVoiceOver, movie: true, save: save)
                    } else if vOExporter!.status == AVAssetExportSessionStatus.Waiting {
                        print("Export waiting")
                    } else if vOExporter!.status == AVAssetExportSessionStatus.Failed {
                        print("Export failure")
                        self.composeMedia(videoAssets, voiceOverAssets: voiceOvers, movieVoiceOver: nil, movie: true, save: save)
                    }
        }
    }

    
    func composeMedia(videoAssets: [AVURLAsset], voiceOverAssets: [AVURLAsset], movieVoiceOver: AVURLAsset?, movie: Bool, save: Bool) {
        defer {
                NSNotificationCenter.defaultCenter().postNotificationName(Notifications.previewReady, object: self)
        }
        
        // Get total time for movie assets.
        var totalTime: CMTime = kCMTimeZero
        for time in videoAssets {
            totalTime = CMTimeAdd(totalTime, time.duration)
        }
        
        // Compose assets into a scene or movie.
        let mixComposition = AVMutableComposition()
        var tracks = [AVMutableCompositionTrack]()
        var tracksTime: CMTime = kCMTimeZero
        
        // create instructions for each track
        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalTime)
        var instructions = [AVMutableVideoCompositionLayerInstruction]()
        
        // Video
        for videoAsset in videoAssets {
            // TODO: Post notifiction for composition failure.
            // create tracks for each video asset
            if !videoAsset.tracks.isEmpty {
                let track = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo,
                    preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
                do {
                    try track.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration),
                        ofTrack: videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0] ,
                        atTime: tracksTime)
                } catch let firstTrackError as NSError {
                    print(firstTrackError.localizedDescription)
                }

            tracks.append(track)
            tracksTime = CMTimeAdd(tracksTime, videoAsset.duration)
            // creat instructions for each track
            let instruction = self.videoCompositionInstructionForTrack(track, asset: videoAsset)
            instruction.setOpacity(0.0, atTime: tracksTime)
            instructions.append(instruction)
            }
            
        }
        
        // Add individual instructions to main for execution.
        mainInstruction.layerInstructions = instructions
        let mainComposition = AVMutableVideoComposition()
        
        // Add instruction composition to main composition and set frame rate to 30 per second.
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(1, 30)
        mainComposition.renderSize = mixComposition.naturalSize
        
        // process audio for each set of videos(scene) if present or not movie
        if !movie {
            for voiceOverAsset in voiceOverAssets {
                if !voiceOverAsset.tracks.isEmpty {
                    let audioTrack: AVMutableCompositionTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
                    do { // TODO: Possibly adjust tracks time to be more comprehensive.
                        try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, tracksTime), ofTrack: voiceOverAsset.tracksWithMediaType(AVMediaTypeAudio)[0] ,
                            atTime: kCMTimeZero)
                    } catch let audioTrackError as NSError{
                        print(audioTrackError.localizedDescription)
                    }
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
                    try mTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, totalTime), ofTrack: self.musicTrack.tracksWithMediaType(AVMediaTypeAudio)[0], atTime: kCMTimeZero)
                } catch let musicTrackError as NSError {
                    print(musicTrackError.localizedDescription)
                }
            }
        }
        
        
        if save {
            self.saveMedia(mixComposition, videoComposition: mainComposition, movie: movie)
        } else {
            let preview = AVPlayerItem(asset: mixComposition)
            preview.videoComposition = mainComposition
            self.preview = preview
        }
    }
    
    
    // MARK: Media save methods
    func saveMedia(mixComposition: AVMutableComposition, videoComposition: AVMutableVideoComposition, movie: Bool) {
        // setup to save
        let paths: NSArray = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentDirectory: String = paths[0] as! String
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .FullStyle
        let date = dateFormatter.stringFromDate(NSDate())
        let url = NSURL(fileURLWithPath: documentDirectory).URLByAppendingPathComponent("mergeVideo-\(date).mov")
        // make exporter
        let exporter = AVAssetExportSession(
            asset: mixComposition,
            presetName: AVAssetExportPresetHighestQuality)
        exporter!.outputURL = url
        exporter!.outputFileType = AVFileTypeQuickTimeMovie
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
            if type == "movie" || type == "scene" {
                saveToDropBox(outputURL)
            }
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
    
    // MARK: Composition helper methods
    func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        var assetOrientation = UIImageOrientation.Up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .Right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .Left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .Up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .Down
        }
        return (assetOrientation, isPortrait)
    }
    
    
    func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0] 
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform)
        
        if assetInfo.orientation == .Down {
            let fixUpsideDown = CGAffineTransformMakeRotation(CGFloat(M_PI))
            let yFix = assetTrack.naturalSize.height
            let centerFix = CGAffineTransformMakeTranslation(assetTrack.naturalSize.width, yFix)
            let concat = CGAffineTransformConcat(fixUpsideDown, centerFix)
            instruction.setTransform(concat, atTime: kCMTimeZero)
        }
        return instruction
    }
    
    
    // MARK: Archiving path methods
    func getScenesArchivePathURL() -> NSURL {
        let documentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let archiveURL = documentsDirectory.URLByAppendingPathComponent("\(self.project!)/scenes")
        return archiveURL
    }
    
    
    func getIntroArchivePathURL() -> NSURL {
        let documentsDirectory = NSFileManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let archiveURL = documentsDirectory.URLByAppendingPathComponent("\(self.project!)/intro")
        return archiveURL
    }
    
    // MARK: Paths for audio and video files.
    func getVoiceOverSavePath(audioSaveID: String) -> NSURL {
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        let filename = "/\(self.project!)/\(audioSaveID).caf"
        let pathArray = [dirPath, filename]
        let url = NSURL.fileURLWithPathComponents(pathArray)!
        print(url.path!)
        return url
    }
    
    
    func getIntroShotSavePath() -> NSURL {
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        let filename = "/\(self.project!)/intro.mov"
        let pathArray = [dirPath, filename]
        let url = NSURL.fileURLWithPathComponents(pathArray)!
        print("Intro shot save path: \(url.path!)")
        return url
    }
    
    
    func getPathForFileInDocumentsDirectory(fileName: String) -> NSURL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        let directoryPath = documentsPath + "/\(self.project!)"
        let pathArray = [directoryPath, fileName]
        let url = NSURL.fileURLWithPathComponents(pathArray)!
        print("Path for file: \(url.path!)")
        return url
    }
    
    // MARK: NSCoding
    func saveScenes() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(scenes, toFile: getScenesArchivePathURL().path!)
        if !isSuccessfulSave {
            print("FAILED TO SAVE Scenes\(getScenesArchivePathURL().path!)")
        }
    }
    
    
    func saveIntro() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(intro, toFile: self.getIntroArchivePathURL().path!)
        if !isSuccessfulSave {
            print("Intro save failure!!")
        }
    }
    
    
    func loadScenes() -> [Scene]! {
        guard let loadedScenes = NSKeyedUnarchiver.unarchiveObjectWithFile(getScenesArchivePathURL().path!) as! [Scene]! else {
            let scenesContainer = [Scene]()
            return scenesContainer
        }
        return loadedScenes
    }
    
    
    func loadIntro() -> Intro? {
        return NSKeyedUnarchiver.unarchiveObjectWithFile(self.getIntroArchivePathURL().path!) as? Intro
    }
    
    
    // MARK: DropBox
    func saveToDropBox(filePath: NSURL!) {
    // Verify user is logged into Dropbox
        if let client = Dropbox.authorizedClient {
            // Get the current user's account info
            client.users.getCurrentAccount().response { response, error in
                print("*** Get current account ***")
                if let account = response {
                    print("Hello \(account.name.givenName)!")
                } else {
                    print(error!.description)
                }
            }
            
            // Upload a file
            let fileData = NSData(contentsOfFile: filePath.path!)
            client.files.upload(path: "/\(filePath!.lastPathComponent!)", body: fileData!).response { response, error in
                if let metadata = response {
                    print("*** Upload file ****")
                    print("Uploaded file name: \(metadata.name)")
                    print("Uploaded file revision: \(metadata.rev)")
                    
                } else {
                    print("DROPBOX FAILURE\(error!.description)")
                }
            }
        }//client
    }
}
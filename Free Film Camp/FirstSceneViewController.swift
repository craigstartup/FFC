//  Assisted by http://www.raywenderlich.com/94404/play-record-merge-videos-ios-swift
//  SceneBuilderViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/5/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import Photos
import AVFoundation


class FirstSceneViewController: UIViewController {

    
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    let sceneFetchOptions = PHFetchOptions()
    let movieFetchOptions = PHFetchOptions()
    let toAlbumTitle = "Free Film Camp Scenes"
    let movieAlbumTitle = "Free Film Camp Movies"
    let clipID = "s1ClipSelectedSegue"
    let audioID = "s1AudioSelectedSegue"
    var assetRequestNumber: Int!
    var scene = 1
    
    var selectedVideoAsset: NSURL!
    var audioAsset: AVAsset!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set up album for recorded scenes and movies
        self.sceneFetchOptions.predicate = NSPredicate(format: "title = %@", self.toAlbumTitle)
        
        let toAlbum = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: self.sceneFetchOptions)
        
        if let _: AnyObject = toAlbum.firstObject {
            
            print("Free Film Camp Scenes exists")
        } else {
            
            library.performChanges({ () -> Void in
                
                PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(self.toAlbumTitle)
                
                }) { (success: Bool, error: NSError?) -> Void in
                    if !success {
                        print(error!.localizedDescription)
                    }
            }
            
        }
        
        self.movieFetchOptions.predicate = NSPredicate(format: "title = %@", self.movieAlbumTitle)
        let movieAlbum = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: self.movieFetchOptions)
        
        if let _: AnyObject = movieAlbum.firstObject {
            
            print("Free Film Camp Movies exists")
        } else {
            
            library.performChanges({ () -> Void in
                
                PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(self.movieAlbumTitle)
                
                }) { (success: Bool, error: NSError?) -> Void in
                    if !success {
                        print(error!.localizedDescription)
                    }
            }
            
        }
    }
    
    
    override func viewWillAppear(animated: Bool) {
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
    }

    @IBAction func selectClipOne(sender: AnyObject) {
        
        MediaController.sharedMediaController.s1Shot1 = nil
        self.selectedVideoAsset = nil
        self.assetRequestNumber = 1
        self.performSegueWithIdentifier("s1SelectClip", sender: self)
    }
    
    @IBAction func selectClipTwo(sender: AnyObject) {
        
        MediaController.sharedMediaController.s1Shot2 = nil
        self.selectedVideoAsset = nil
        self.assetRequestNumber = 2
        self.performSegueWithIdentifier("s1SelectClip", sender: self)
    }
    
    @IBAction func selectClip3(sender: AnyObject) {
        
        MediaController.sharedMediaController.s1Shot3 = nil
        self.selectedVideoAsset = nil
        self.assetRequestNumber = 3
        self.performSegueWithIdentifier("s1SelectClip", sender: self)
    }
    
    @IBAction func record(sender: AnyObject) {

    }
    
    @IBAction func previewSelection(sender: AnyObject) {
    }
    
    @IBAction func mergeMedia(sender: AnyObject) {
        
        MediaController.sharedMediaController.saveScene(self.scene)
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    
        if segue.identifier == "s1SelectClip" {
            
            let destinationVC = segue.destinationViewController as! VideosViewController
            destinationVC.segueID = self.clipID
        } else if segue.identifier == "s1SelectAudio" {
            
            let destinationVC = segue.destinationViewController as! VoiceOverViewController
            destinationVC.segueID = self.audioID
        }
    }
    
    // MARK: unwind segues
    @IBAction func s1ClipUnwindSegue(unwindSegue: UIStoryboardSegue) {
        
        if assetRequestNumber == 1 {
            
            MediaController.sharedMediaController.s1Shot1 = AVAsset(URL: self.selectedVideoAsset)
        } else if assetRequestNumber == 2 {
            
            MediaController.sharedMediaController.s1Shot2 = AVAsset(URL: self.selectedVideoAsset)
        } else if assetRequestNumber == 3 {
            
            MediaController.sharedMediaController.s1Shot3 = AVAsset(URL: self.selectedVideoAsset)
        }
    }
    
    @IBAction func s1AudioUnwindSegue(unwindSegue: UIStoryboardSegue){
        
        MediaController.sharedMediaController.s1VoiceOver = self.audioAsset
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

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


class FirstSceneViewController: UIViewController {

    
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    let fetchOptions = PHFetchOptions()
    let toAlbumTitle = "Free Film Camp Scenes"
    var assetRequestNumber: Int!
    var scene = 1
    var clipsVC: UIViewController!
    
    var selectedVideoAsset: NSURL!
    var audioAsset: AVAsset!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clipsVC = storyboard?.instantiateViewControllerWithIdentifier("videoVC") as! ClipsViewController
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
    
    
    override func viewWillAppear(animated: Bool) {
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    @IBAction func selectClipOne(sender: AnyObject) {
        
        self.assetRequestNumber = 1
        presentViewController(self.clipsVC, animated: true, completion: nil)
        
    }
    
    @IBAction func selectClipTwo(sender: AnyObject) {
        
        self.assetRequestNumber = 2
        presentViewController(self.clipsVC, animated: true, completion: nil)    }
    
    @IBAction func selectClip3(sender: AnyObject) {
        
        self.assetRequestNumber = 3
        presentViewController(self.clipsVC, animated: true, completion: nil)
    }
    
    @IBAction func record(sender: AnyObject) {
        
        let vc = storyboard?.instantiateViewControllerWithIdentifier("voiceOverVC") as! VoiceOverViewController
        presentViewController(vc, animated: true, completion: nil)
    }
    
    @IBAction func previewSelection(sender: AnyObject) {
    }
    
    @IBAction func mergeMedia(sender: AnyObject) {
        
        if MediaController.sharedMediaController.saveScene(self.scene) {
            
            let alert = UIAlertController(title: "Success", message: "Video saved.", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: unwind segues
    @IBAction func clipUnwindSegue(unwindSegue: UIStoryboardSegue) {
        
        if assetRequestNumber == 1 {
            
            MediaController.sharedMediaController.s1Shot1 = AVAsset(URL: self.selectedVideoAsset)
        } else if assetRequestNumber == 2 {
            
            MediaController.sharedMediaController.s1Shot2 = AVAsset(URL: self.selectedVideoAsset)
        } else if assetRequestNumber == 3 {
            
            MediaController.sharedMediaController.s1Shot3 = AVAsset(URL: self.selectedVideoAsset)
        }
    }
    
    @IBAction func audioUnwindSegue(unwindSegue: UIStoryboardSegue){
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

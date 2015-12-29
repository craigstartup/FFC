//
//  VideosViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/6/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import Photos
import AVKit

class VideosViewController: UICollectionViewController, UIGestureRecognizerDelegate {

    let library = PHPhotoLibrary.sharedPhotoLibrary()
    let manager = PHImageManager.defaultManager()
    let vpVC = AVPlayerViewController()
    let defaults = NSUserDefaults()

    // fetch albums and assets
    let fetchOptions = PHFetchOptions()
    let albumTitle = "Free Film Camp Clips"
    var clipsAlbumFetch: PHFetchResult!
    var clipsAlbumVideosFetch: PHFetchResult!
    var clipsAlbum: PHAssetCollection!
    let reuseIdentifier = "ClipCell"
    var videos = [PHAsset]()
    
    // handle interaction
    var longPress: UILongPressGestureRecognizer!
    var tap: UITapGestureRecognizer!
    var timer: NSTimer!
    var longItem: CGPoint!
    
    // handle logic based on presenting VC
    var segueID = "sceneShotSelectedSegue"
    var shotNumber: Int!
    
    // pass back selected video and image
    var videoAssetToPass: NSURL!
    var initialEntry = true
    var videoImageToPass: UIImage!
    
    // Mark: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // retrieve or creat clips album
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumTitle)
        clipsAlbumFetch = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        
        if let _: AnyObject = clipsAlbumFetch.firstObject {
            clipsAlbum = clipsAlbumFetch.firstObject as! PHAssetCollection
            print("Free Film Camp Clips exists")
            // setup to retrieve videos from clips album
            clipsAlbumVideosFetch = PHAsset.fetchAssetsInAssetCollection(clipsAlbum, options: nil)
        } else {
            library.performChanges({ () -> Void in
                PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(self.albumTitle)
                }) { (success: Bool, error: NSError?) -> Void in
                    if !success {
                        print(error!.localizedDescription)
                    }
            }
        }
        
        // setup gesture recognizer
        longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
        longPress.minimumPressDuration = 0.3
        longPress.delegate = self
        longPress.delaysTouchesBegan = true
        self.collectionView?.addGestureRecognizer(longPress)
        tap = UITapGestureRecognizer(target: self, action: "handleTap:")
        tap.delegate = self
        self.collectionView?.addGestureRecognizer(tap)
        // tell user how to use
        if defaults.objectForKey("initialEntry") != nil{
            initialEntry = (defaults.objectForKey("initialEntry") as? Bool)!
        }
        
        if initialEntry {
            initialEntry = false
            defaults.setObject(initialEntry, forKey: "initialEntry")
            defaults.synchronize()
            let alert = UIAlertController(title: "Welcome", message: "Tap image to select. Tap and hold to play.", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        self.videos = [PHAsset]()
        if self.clipsAlbumVideosFetch != nil {
            clipsAlbumVideosFetch.enumerateObjectsUsingBlock { (object, _, _) in
                if let asset = object as? PHAsset {
                    self.videos.append(asset)
                }
            }
        }
        
        self.navigationController?.navigationBar.translucent = true
    }
    
    // MARK: Collection view delegate methods
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if clipsAlbum.estimatedAssetCount > 0 {
            return clipsAlbum.estimatedAssetCount + 1
        } else {
            return 1
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        return CGSizeMake((UIScreen.mainScreen().bounds.width-20)/3,136);
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cameraCell = collectionView.dequeueReusableCellWithReuseIdentifier("cameraCell", forIndexPath: indexPath)
            return cameraCell
        } else {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! VideoLibraryCell
            
            if cell.tag != 0 {
                manager.cancelImageRequest(PHImageRequestID(cell.tag))
            }
            let video = videos[indexPath.row - 1]
            cell.tag = Int(manager.requestImageForAsset(video,
                targetSize: CGSize(width: 215, height: 136),
                contentMode: .AspectFill,
                options: nil) { (result, _) -> Void in
                    cell.imageView.image = result
            })
            cell.destroyClipButton.tag = indexPath.row
            cell.destroyClipButton.addTarget(self, action: "destroyClip:", forControlEvents: UIControlEvents.TouchUpInside)
            return cell
        }
    }
    
    // MARK: Media selection methods
    @IBAction func cancelSelection(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == UIGestureRecognizerState.Began {
            self.longItem = gestureRecognizer.locationInView(self.collectionView)
            timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "endLongPress:", userInfo: nil, repeats: false)
        } else if gestureRecognizer.state == UIGestureRecognizerState.Ended {
            self.timer.invalidate()
            self.timer = nil
            self.longItem = nil
        }
    }
    
    func endLongPress(timer: NSTimer!) {
        let indexPath = self.collectionView?.indexPathForItemAtPoint(self.longItem)
        var videoPlayer: AVPlayer!
        if indexPath!.row > 0 {
            let video = videos[(indexPath?.row)! - 1]
            manager.requestPlayerItemForVideo(video, options: nil) { (playerItem, info) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    videoPlayer = AVPlayer(playerItem: playerItem!)
                    self.vpVC.player = videoPlayer
                    self.vpVC.modalPresentationStyle = UIModalPresentationStyle.OverFullScreen
                    self.presentViewController(self.vpVC, animated: true, completion: nil)
                })
            }
        }
    }
    
    func handleTap(gestureRecognizer: UITapGestureRecognizer) {
        print("TAP")
        if gestureRecognizer.state != UIGestureRecognizerState.Ended {
            return
        }
        let itemTouched = gestureRecognizer.locationInView(self.collectionView)
        let indexPath = self.collectionView?.indexPathForItemAtPoint(itemTouched)
        
        if indexPath?.row > 0 {
            let video = videos[(indexPath?.row)! - 1]
            manager.requestImageForAsset(video,
                targetSize: CGSize(width: 215, height: 136),
                contentMode: .AspectFill,
                options: nil) { [unowned self] (result, _) -> Void in
                    self.videoImageToPass = result!
            }
            manager.requestAVAssetForVideo(video, options: nil) { (videoAsset, audioMix, info) -> Void in
                dispatch_async(dispatch_get_main_queue(), { [unowned self] () -> Void in
                    if (videoAsset?.isKindOfClass(AVURLAsset) != nil) {
                        let url = videoAsset as! AVURLAsset
                        self.videoAssetToPass = url.URL
                        self.performSegueWithIdentifier(self.segueID, sender: self)
                    }
                })
            }
        }
    }
    
    func destroyClip(sender: UIButton) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            print("DESTROYED")
            print(sender.tag)
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                if self.videos[sender.tag - 1].canPerformEditOperation(PHAssetEditOperation.Delete){
                    let target = self.videos[sender.tag - 1]
                    PHAssetChangeRequest.deleteAssets([target])
                    }
                }, completionHandler: { (success, error) -> Void in
                    if success {
                        print("DESTROYED")
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.videos.removeAtIndex(sender.tag - 1)
                        self.collectionView?.reloadData()
                    })
                        
                    } else if error != nil {
                        print(error?.localizedDescription)
                    }
            })
        }
    }
    
    // MARK: Segue methods
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == self.segueID {
            let sceneVC = segue.destinationViewController as! SceneViewController
            sceneVC.selectedVideoAsset = self.videoAssetToPass
            sceneVC.selectedVideoImage = self.videoImageToPass
            sceneVC.setupView()
        } else if segue.identifier == "pickingShot" {
            let cameraVC = segue.destinationViewController as! CameraViewController
            cameraVC.pickingShot = true
            cameraVC.segueToPerform = "cameraUnwindSegue"
        }
    }
    
    @IBAction func cameraUnwind(unwindSegue: UIStoryboardSegue) {
        self.performSegueWithIdentifier(self.segueID, sender: self)
    }
}

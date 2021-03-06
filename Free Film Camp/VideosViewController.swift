//
//  VideosViewController.swift
//  Film Camp
//
//  Created by Eric Mentele on 10/6/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import Photos
import AVKit

class VideosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    let manager = PHImageManager.defaultManager()
    let vpVC = AVPlayerViewController()
    let defaults = NSUserDefaults()

    // fetch albums and assets
    let fetchOptions = PHFetchOptions()
    let requestOptions = PHImageRequestOptions()
    let albumTitle = "Film Camp Clips"
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
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        
        // retrieve or creat clips album
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumTitle)
        clipsAlbumFetch = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .AlbumRegular, options: fetchOptions)
        
        if let _: AnyObject = clipsAlbumFetch.firstObject {
            clipsAlbum = clipsAlbumFetch.firstObject as! PHAssetCollection
            print("Film Camp Clips exists")
            // setup to retrieve videos from clips album
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            clipsAlbumVideosFetch = PHAsset.fetchAssetsInAssetCollection(clipsAlbum, options: options)
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
        
        self.videos = [PHAsset]()
        
        if self.clipsAlbumVideosFetch != nil {
            clipsAlbumVideosFetch.enumerateObjectsUsingBlock { (object, _, _) in
                if let asset = object as? PHAsset {
                    self.videos.append(asset)
                }
            }
        }
        
        // configure image request options
        requestOptions.deliveryMode = .Opportunistic
        requestOptions.networkAccessAllowed = true
        
        //self.setCollectionViewLayout()
        self.navigationController?.navigationBar.translucent = true
    }
    
    override func viewDidAppear(animated: Bool) {
        if initialEntry {
            initialEntry = false
            defaults.setObject(initialEntry, forKey: "initialEntry")
            defaults.synchronize()
            let alert = UIAlertController(title: "Welcome", message: "Tap image to select. Tap and hold to play.", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(action)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: Collection view layout.
    func setCollectionViewLayout() {
        let nCells: CGFloat = 3
        let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let availableCellWidth = CGRectGetWidth(self.collectionView.frame)
        let cellWidth = availableCellWidth / nCells
        layout.itemSize = CGSizeMake(cellWidth, cellWidth)
    }
    
    // MARK: Collection view delegate methods
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.videos.count
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        let cellWidth = self.collectionView.bounds.width / 3
        return CGSizeMake(cellWidth, cellWidth);
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! VideoLibraryCell
        manager.cancelImageRequest(PHImageRequestID(cell.tag))
        
        let video = videos[indexPath.row]
        
        cell.tag = Int(manager.requestImageForAsset(video,
            targetSize: CGSize(width: 215, height: 136),
            contentMode: .AspectFill,
            options: requestOptions) { (result, resultInfo) -> Void in
                cell.imageView.image = result
            })
        
        cell.destroyClipButton.tag = indexPath.row
        cell.destroyClipButton.addTarget(self, action: "destroyClip:", forControlEvents: UIControlEvents.TouchUpInside)
        return cell
    }
    
    // MARK: Media selection methods
    @IBAction func cancelSelection(sender: UIButton) {
        NSNotificationCenter.defaultCenter().postNotificationName(MediaController.Notifications.toolViewDismissed, object: self)
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
        if indexPath?.row >= 0 {
            let video = videos[(indexPath?.row)!]
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
        
        if indexPath?.row >= 0 {
             NSNotificationCenter.defaultCenter().postNotificationName(MediaController.Notifications.toolViewDismissed, object: self)
            let video = videos[(indexPath?.row)!]
            
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
                if self.videos[sender.tag].canPerformEditOperation(PHAssetEditOperation.Delete){
                    let target = self.videos[sender.tag]
                    PHAssetChangeRequest.deleteAssets([target])
                    }
                }, completionHandler: { (success, error) -> Void in
                    if success {
                        print("DESTROYED")
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.videos.removeAtIndex(sender.tag)
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
        } else if segue.identifier == "pickingShot" {
            let cameraVC = segue.destinationViewController as! CameraViewController
            cameraVC.pickingShot = true
            cameraVC.segueToPerform = "cameraUnwindSegue"
        }
    }
    
    @IBAction func cameraUnwind(unwindSegue: UIStoryboardSegue) {
        NSNotificationCenter.defaultCenter().postNotificationName(MediaController.Notifications.toolViewDismissed, object: self)
        self.performSegueWithIdentifier(self.segueID, sender: self)
    }
    
    // MARK: Photos observation
//    func indexPathsFromIndexSet(indexSet: NSIndexSet) -> NSArray {
//        let indexPaths = NSMutableArray()
//        
//        indexSet.enumerateIndexesUsingBlock { (indecie, stop) -> Void in
//            let indexPath = NSIndexPath(forItem: indecie, inSection: 0)
//            indexPaths.addObject(indexPath)
//        }
//        return indexPaths
//    }
    
//    func photoLibraryDidChange(changeInstance: PHChange) {
//        dispatch_async(dispatch_get_main_queue()) {
//            if let collectionChanges = changeInstance.changeDetailsForFetchResult(self.clipsAlbumVideosFetch) {
//                self.clipsAlbumVideosFetch = collectionChanges.fetchResultAfterChanges
//                
//                if collectionChanges.hasIncrementalChanges {
//                    
//                    // Get the changes as lists of index paths for updating the UI.
//                    var removedPaths: [NSIndexPath]?
//                    var insertedPaths: [NSIndexPath]?
//                    var changedPaths: [NSIndexPath]?
//                    
//                    if let removed = collectionChanges.removedIndexes {
//                        removedPaths = self.indexPathsFromIndexSet(removed) as? [NSIndexPath]
//                    }
//                    if let inserted = collectionChanges.insertedIndexes {
//                        insertedPaths = self.indexPathsFromIndexSet(inserted) as? [NSIndexPath]
//                    }
//                    if let changed = collectionChanges.changedIndexes {
//                        changedPaths = self.indexPathsFromIndexSet(changed) as? [NSIndexPath]
//                    }
//                    
//                    // Tell the collection view to animate insertions/deletions/moves
//                    // and to refresh any cells that have changed content.
//                    self.collectionView.performBatchUpdates(
//                        {
//                            if (removedPaths != nil) {
//                                self.collectionView.deleteItemsAtIndexPaths(removedPaths!)
//                            }
//                            if (insertedPaths != nil) {
//                                self.collectionView.insertItemsAtIndexPaths(insertedPaths!)
//                            }
//                            if (changedPaths != nil) {
//                                self.collectionView.reloadItemsAtIndexPaths(changedPaths!)
//                            }
//                            if (collectionChanges.hasMoves) {
//                                collectionChanges.enumerateMovesWithBlock() { fromIndex, toIndex in
//                                    let fromIndexPath = NSIndexPath(forItem: fromIndex, inSection: 0)
//                                    let toIndexPath = NSIndexPath(forItem: toIndex, inSection: 0)
//                                    self.collectionView.moveItemAtIndexPath(fromIndexPath, toIndexPath: toIndexPath)
//                                }
//                            }
//                        }, completion: nil)
//                } else {
//                    // Detailed change information is not available;
//                    // repopulate the UI from the current fetch result.
//                    self.collectionView.reloadData()
//                }
//            }
//        }
//    }
}

//
//  ClipsViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/6/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit
import Photos
import AVKit

class TheatreViewController: UICollectionViewController {
    
    let library = PHPhotoLibrary.sharedPhotoLibrary()
    let manager = PHImageManager.defaultManager()
    let vpVC = AVPlayerViewController()
    let defaults = NSUserDefaults()
    
    // fetch albums and assets
    let fetchOptions = PHFetchOptions()
    let albumTitle = "Free Film Camp Scenes"
    var clipsAlbumFetch: PHFetchResult!
    var clipsAlbumVideosFetch: PHFetchResult!
    var clipsAlbum: PHAssetCollection!
    let reuseIdentifier = "TheatreCell"
    var videos = [PHAsset]()
    
    // handle interaction
    var longPress: UILongPressGestureRecognizer!
    var tap: UITapGestureRecognizer!
    
    // pass back selected video
    var videoAssetToPass: NSURL!
    var initialEntry = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // retrieve or creat clips album
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumTitle)
        clipsAlbumFetch = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        clipsAlbum = clipsAlbumFetch.firstObject as! PHAssetCollection
        if let _: AnyObject = clipsAlbumFetch.firstObject {
            
            print("Free Film Camp Clips exists")
        } else {
            
            library.performChanges({ () -> Void in
                PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(albumTitle)
                }) { (success: Bool, error: NSError?) -> Void in
                    if !success {
                        print(error!.localizedDescription)
                    }
            }
            
        }
        
        // retrieve videos from clips album
        clipsAlbumVideosFetch = PHAsset.fetchAssetsInAssetCollection(clipsAlbum, options: nil)
        
        clipsAlbumVideosFetch.enumerateObjectsUsingBlock { (object, _, _) in
            if let asset = object as? PHAsset {
                self.videos.append(asset)
            }
        }
        
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return clipsAlbum.estimatedAssetCount
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! TheatreCell
        cell.backgroundColor = UIColor.blueColor()
        
        if cell.tag != 0 {
            
            manager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        
        let video = videos[indexPath.row]
        
        cell.tag = Int(manager.requestImageForAsset(video,
            targetSize: CGSize(width: 140, height: 140),
            contentMode: .AspectFill,
            options: nil) { (result, _) -> Void in
                cell.imageView.image = result
            })
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        print("tapped item")

        let video = videos[(indexPath.row)]
        manager.requestPlayerItemForVideo(video, options: nil) { (playerItem, info) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                let videoPlayer = AVPlayer(playerItem: playerItem!)
                //let layer = AVPlayerLayer(player: videoPlayer)
                //layer.frame = self.view.bounds
                //self.view.layer.addSublayer(layer)
                //videoPlayer.play()
                self.vpVC.player = videoPlayer
                self.presentViewController(self.vpVC, animated: true, completion: nil)
            })
            
        }
       
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

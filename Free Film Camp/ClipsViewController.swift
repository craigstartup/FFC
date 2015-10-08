//
//  ClipsViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/6/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit
import Photos

class ClipsViewController: UICollectionViewController {

    let library = PHPhotoLibrary.sharedPhotoLibrary()
    let cachingManager = PHCachingImageManager()
    // fetch albums and assets
    let fetchOptions = PHFetchOptions()
    let albumTitle = "Free Film Camp Clips"
    var clipsAlbumFetch: PHFetchResult!
    var clipsAlbumVideosFetch: PHFetchResult!
    var clipsAlbum: PHAssetCollection!
    let reuseIdentifier = "ClipCell"
    var videos = [PHAsset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBarHidden = false
        
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumTitle)
        clipsAlbumFetch = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        clipsAlbum = clipsAlbumFetch.firstObject as! PHAssetCollection
        if let _: AnyObject = clipsAlbumFetch.firstObject {
            
            print("Free Film Camp Clips exists")
            print(clipsAlbum.description)
        } else {
            
            library.performChanges({ () -> Void in
                PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(albumTitle)
                }) { (success: Bool, error: NSError?) -> Void in
                    if !success {
                        print(error!.localizedDescription)
                    }
            }
            
        }
        
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
        
        let manager = PHImageManager.defaultManager()
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! VideoLibraryCell
        cell.backgroundColor = UIColor.redColor()
        
        if cell.tag != 0 {
            
            manager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        
        let video = videos[indexPath.section]
        
        cell.tag = Int(manager.requestImageForAsset(video,
            targetSize: CGSize(width: 100, height: 100),
            contentMode: .AspectFill,
            options: nil) { (result, _) -> Void in
                cell.imageView.image = result
        })
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        
        print(indexPath.description)
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

//
//  MovieBuilderViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/5/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import Photos
import AVKit


class MovieBuilderViewController: UIViewController {
    
    @IBOutlet weak var savingProgress: UIActivityIndicatorView!
    @IBOutlet weak var headshot: UIImageView!
    
    var vpVC = AVPlayerViewController()
    var previewQueue = [AVPlayerItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        MediaController.sharedMediaController.prepareMovie(false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        MediaController.sharedMediaController.moviePreview = nil 
    }
    
    
    @IBAction func addHeadshot(sender: AnyObject) {
    }

    @IBAction func addMusic(sender: AnyObject) {
    }
    
    @IBAction func makeMovie(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveCompleted:", name: "saveComplete", object: nil)
        self.savingProgress.alpha = 1
        self.savingProgress.startAnimating()
        MediaController.sharedMediaController.prepareMovie(true)
    }
    
    func saveCompleted(notification: NSNotification) {
        self.savingProgress.stopAnimating()
        self.savingProgress.alpha = 0
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @IBAction func preview(sender: AnyObject) {
        
        if MediaController.sharedMediaController.moviePreview != nil {
            var videoPlayer = AVPlayer()
            videoPlayer = AVPlayer(playerItem: MediaController.sharedMediaController.moviePreview)
            self.vpVC.player = videoPlayer
            self.presentViewController(self.vpVC, animated: true, completion: nil)
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

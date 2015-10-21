//
//  MovieBuilderViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 10/5/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import Photos


class MovieBuilderViewController: UIViewController {
    
    @IBOutlet weak var headshot: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    
    @IBAction func addHeadshot(sender: AnyObject) {
    }

    @IBAction func addMusic(sender: AnyObject) {
    }
    
    @IBAction func makeMovie(sender: AnyObject) {
        
        MediaController.sharedMediaController.saveMovie()
    }
    
    @IBAction func preview(sender: AnyObject) {
        
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

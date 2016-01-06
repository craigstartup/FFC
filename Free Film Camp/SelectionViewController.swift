//  SelectionViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 11/1/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit

class SelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    enum TabButtons {
        static let INTRO   = 1
        static let SCENE_1 = 2
        static let SCENE_2 = 3
        static let SCENE_3 = 4
        static let MOVIE   = 5
    }
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet var buttons: Array<UIButton>!
    
    var lastSegue: String!
    
    let defaultImage         = UIImage(named: "plus_white_69")
    let defaultVideoURL      = NSURL(string: "placeholder")
    let defaultVoiceOverFile = "placeholder"

    var viewControllers      = [UIViewController]()
    var scrollViewPages      = [CGRect]()
    let viewControllerIds    = ["IntroViewController","SceneViewController","MovieBuilderViewController"]
    
    var currentVC = 0
    var currentButton = 0
    let transitionQueue = dispatch_queue_create("com.trans.Queue", nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "dropboxComplete:",
            name: MediaController.Notifications.dropBoxUpFinish,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "projectChanged:",
            name: "projectSelected", 
            object: nil)
        
        self.navigationController?.navigationBarHidden = true
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.getViewControllersForPages()
    }
    
    // MARK: Scrollview setup methods
    func getViewControllersForPages() {
        // Load scenes or initialize if none exist.
        MediaController.sharedMediaController.scenes = MediaController.sharedMediaController.loadScenes()
        
        if MediaController.sharedMediaController.scenes.isEmpty {
            for _ in 0..<3 {
                let scene = Scene(shotVideos: Array(count: 3, repeatedValue: defaultVideoURL!), shotImages: Array(count: 3, repeatedValue: defaultImage!), voiceOver: defaultVoiceOverFile)
                MediaController.sharedMediaController.scenes.append(scene!)
            }
        }
        
        var index = 0
        
        for viewId in self.viewControllerIds {
            if viewId == "SceneViewController" {
                for var i = 0; i < MediaController.sharedMediaController.scenes.count; i += 1 {
                    let sceneViewController = self.storyboard?.instantiateViewControllerWithIdentifier(viewId) as? SceneViewController
                    sceneViewController!.sceneNumber = i
                    sceneViewController!.index = index
                    self.viewControllers.append(sceneViewController!)
                    index += 1
                }
            } else {
                var viewController: UIViewController!
                
                if viewId == "IntroViewController" {
                    let introViewController = self.storyboard?.instantiateViewControllerWithIdentifier(viewId) as? IntroViewController
                    introViewController!.index = index
                    viewController = introViewController
                } else if viewId == "MovieBuilderViewController" {
                    let movieViewController = self.storyboard?.instantiateViewControllerWithIdentifier(viewId) as? MovieBuilderViewController
                    movieViewController!.index = index
                    viewController = movieViewController
                }
                
                self.viewControllers.append(viewController!)
                index += 1
            }
        }
    }
    
    // MARK: Table view delegate methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewControllers.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(self.tableView.bounds.height / 1.5)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("viewCell") as! SelectionViewCell
        let view = self.viewControllers[indexPath.row].view
        view.frame = cell.cellViewView.bounds
        cell.cellViewView.addSubview(view)
        return cell
    }
    
    // MARK: Notification methods
    func dropboxComplete(notification: NSNotification) {
        let dropboxAlert = UIAlertController(
            title: "Dropbox Upload Complete",
            message: "Video uploaded to app Dropbox folder",
            preferredStyle: .Alert)
        let okAction = UIAlertAction(
            title: "OK",
            style: .Default,
            handler: { (action) -> Void in
                NSNotificationCenter.defaultCenter().removeObserver(self, name: MediaController.Notifications.dropBoxUpFinish, object: nil)
        })
        
        dropboxAlert.addAction(okAction)
        self.presentViewController(dropboxAlert, animated: true, completion: nil)
    }
    
    func projectChanged(notification: NSNotification) {
        
        self.viewControllers.removeAll()
        self.getViewControllersForPages()
    }
}

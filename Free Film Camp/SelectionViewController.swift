//  SelectionViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 11/1/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit

class SelectionViewController: UIViewController, UIScrollViewDelegate {
    enum TabButtons {
        static let INTRO   = 1
        static let SCENE_1 = 2
        static let SCENE_2 = 3
        static let SCENE_3 = 4
        static let MOVIE   = 5
    }
    
    var pageViewController: UIPageViewController!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var buttonsScrollView: UIScrollView!
    @IBOutlet weak var buttonsStack: UIStackView!
    @IBOutlet var buttons: Array<UIButton>!
    
    var lastSegue: String!
    
    let defaultImage         = UIImage(named: "plus_white_69")
    let defaultVideoURL      = NSURL(string: "placeholder")
    let defaultVoiceOverFile = "placeholder"

    var viewControllers      = [UIViewController]()
    var scrollViewPages      = [CGRect]()
    let viewControllerIds    = ["IntroViewController","SceneViewController","MovieBuilderViewController"]
    
    var currentVC = 1
    var currentButton = 1
    let transitionQueue = dispatch_queue_create("com.trans.Queue", nil)
    var setupComplete = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load scenes or initialize if none exist.
        MediaController.sharedMediaController.scenes = MediaController.sharedMediaController.loadScenes()
        
        if MediaController.sharedMediaController.scenes.isEmpty {
            for _ in 0..<3 {
                let scene = Scene(shotVideos: Array(count: 3, repeatedValue: defaultVideoURL!), shotImages: Array(count: 3, repeatedValue: defaultImage!), voiceOver: defaultVoiceOverFile)
                MediaController.sharedMediaController.scenes.append(scene!)
            }
        }
        
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

        self.getViewControllersForPages()
        
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewWillLayoutSubviews() {
            setupComplete = true
            self.setupScrollView()
            self.populateScrollView()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.getPagePositions()
        self.scrollView.scrollRectToVisible(self.scrollViewPages[self.currentVC], animated: false)
        self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    // MARK: Scrollview setup methods
    func getViewControllersForPages() {
        var index = 0
        for viewId in self.viewControllerIds {
            if viewId == "SceneViewController" {
                for var i = 0; i < MediaController.sharedMediaController.scenes.count; i++ {
                    let sceneViewController = self.storyboard?.instantiateViewControllerWithIdentifier(viewId) as? SceneViewController
                    sceneViewController!.sceneNumber = i
                    sceneViewController!.index = index
                    self.viewControllers.append(sceneViewController!)
                    index++
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
                index++
            }
        }
    }
    
    func setupScrollView() {
        self.scrollView.delegate = self
        let pagesScrollViewFrame = self.scrollView.frame.size
        self.scrollView.contentSize = CGSize(width: pagesScrollViewFrame.width * CGFloat(self.viewControllers.count), height: pagesScrollViewFrame.height)
        self.buttons[self.currentButton].selected = true
    }
    
    func populateScrollView() {
        var frame = self.scrollView.bounds
        for var i = 0; i < self.viewControllers.count; i++ {
            let pageView = viewControllers[i].view
            frame.origin.x = frame.size.width * CGFloat(i)
            frame.origin.y = 0.0
            pageView.contentMode = .ScaleAspectFit
            pageView.frame = frame
            self.scrollView.addSubview(pageView)
        }
    }
    
    func getPagePositions() {
        let pageWidth = self.scrollView.contentSize.width / CGFloat(self.viewControllers.count)
        for var page = 0; page < self.viewControllers.count; page++ {
            let frame = CGRectMake(pageWidth * CGFloat(page), 0.0, self.scrollView.bounds.width, self.scrollView.bounds.height)
            self.scrollViewPages.append(frame)
        }
    }
    
    // MARK: Tab bar navigation button actions
    @IBAction func selectScene(sender: UIButton) {
        self.buttons[self.currentButton].selected = false
        // TODO: Check for capture of self.
        self.currentVC = sender.tag - 1
        UIView.animateWithDuration(1.5) {() -> Void in
             self.scrollView.scrollRectToVisible(self.scrollViewPages[self.currentVC], animated: false)
        }
       
        self.currentButton = sender.tag - 1
        self.buttons[self.currentButton].selected = true
    }
    
    // MARK: Scrollview delegate methods
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.buttons[currentButton].selected = false
        self.currentButton = Int(self.scrollView.contentOffset.x / scrollView.frame.size.width)
        self.buttons[currentButton].selected = true
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
        for view in scrollView.subviews {
            view.removeFromSuperview()
        }
        
        self.populateScrollView()
    }
}

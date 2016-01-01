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
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var buttonsStack: UIStackView!
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

        self.getViewControllersForPages()
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    override func viewWillLayoutSubviews() {
        self.setupScrollView()
        self.populateScrollView()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.getPagePositions()
        //self.selectScene(buttons[1])
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
    
    func setupScrollView() {
        self.scrollView.delegate = self
        let pagesScrollViewFrame = self.scrollView.frame.size
        self.scrollView.contentSize = CGSize(width: pagesScrollViewFrame.width, height: pagesScrollViewFrame.height * CGFloat(self.viewControllers.count))
        self.buttons[self.currentButton].selected = true
    }
    
    func populateScrollView() {
        var frame = self.scrollView.bounds
        for var i = 0; i < self.viewControllers.count; i += 1 {
            let pageView = viewControllers[i].view
            frame.origin.x = 0.0
            frame.origin.y = frame.size.height * CGFloat(i)
            pageView.contentMode = .ScaleAspectFit
            pageView.frame = frame
            self.scrollView.addSubview(pageView)
        }
    }
    
    func getPagePositions() {
        let pageWidth = self.scrollView.contentSize.width / CGFloat(self.viewControllers.count)
        for var page = 0; page < self.viewControllers.count; page += 1 {
            let frame = CGRectMake(pageWidth * CGFloat(page), 0.0, self.scrollView.bounds.width, self.scrollView.bounds.height)
            self.scrollViewPages.append(frame)
        }
    }
    
//    // MARK: Tab bar navigation button actions
//    @IBAction func selectScene(sender: UIButton) {
//        self.buttons[self.currentButton].selected = false
//        // TODO: Check for capture of self.
//        let itemTime = 1.5 / Double(self.buttons.count - 1)
//        let distance = Double(abs(currentButton - sender.tag + 1))
//        let totalAnimationTime = NSTimeInterval(itemTime * distance)
//        self.currentVC = sender.tag - 1
//        self.currentButton = sender.tag - 1
//        
//        UIView.animateWithDuration(totalAnimationTime) {() -> Void in
//             self.scrollView.scrollRectToVisible(self.scrollViewPages[self.currentVC], animated: false)
//             self.buttonSelectedImage.frame.origin = self.buttons[self.currentButton].frame.origin
//        }
//
//        self.buttons[self.currentButton].selected = true
//    }
    
//    // MARK: Scrollview delegate methods
//    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
//        self.buttons[currentButton].selected = false
//        self.currentButton = Int(targetContentOffset.memory.x / scrollView.frame.size.width)
//        
//        self.buttons[currentButton].selected = true
//        
//        UIView.animateWithDuration(0.42) {() -> Void in
//            self.buttonSelectedImage.frame.origin = self.buttons[self.currentButton].frame.origin
//        }
//    }
//    
//    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
//        if !decelerate
//        {
//            let currentIndex = floor(scrollView.contentOffset.x / scrollView.bounds.size.width);
//            
//            let offset = CGPointMake(scrollView.bounds.size.width * currentIndex, 0)
//            
//            scrollView.setContentOffset(offset, animated: true)
//        }
//    }
    
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
        
        self.viewControllers.removeAll()
        self.getViewControllersForPages()
        self.populateScrollView()
    }
}

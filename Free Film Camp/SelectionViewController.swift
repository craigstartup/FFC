//  assisted by http://swiftiostutorials.com/tutorial-custom-tabbar-storyboard/
//  SelectionViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 11/1/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit

class SelectionViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    enum TabButtons {
        static let INTRO   = 1
        static let SCENE_1 = 2
        static let SCENE_2 = 3
        static let SCENE_3 = 4
        static let MOVIE   = 5
    }
    
    var pageViewController: UIPageViewController!
    @IBOutlet weak var viewsView: UIView!
    @IBOutlet var buttons: Array<UIButton>!
    
    var lastSegue: String!
    
    let defaultImage              = UIImage(named: "plus_white_69")
    let defaultVideoURL           = NSURL(string: "placeholder")
    let defaultVoiceOverFile      = "placeholder"
    
    var viewControllers = [UIViewController]()
    let viewControllerIds = ["IntroViewController","SceneViewController","MovieBuilderViewController"]
    
    var currentVC = 0
    var swiped = false
    
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

        self.setupPageViewController()
        self.navigationController?.navigationBarHidden = true
    }
    
    
    func setupPageViewController() {
        guard let pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("pageVC") as? UIPageViewController else {return}
        
        self.pageViewController = pageViewController
        self.pageViewController.dataSource = self
        self.getViewControllers()
        self.pageViewController.setViewControllers([self.viewControllers[self.currentVC]], direction: .Forward, animated: false, completion: nil)
        
        self.pageViewController.view.frame = self.viewsView.bounds
        self.viewsView.addSubview(self.pageViewController.view)
        self.addChildViewController(self.pageViewController)
        self.pageViewController.didMoveToParentViewController(self)
    }
    
    
    func getViewControllers() {
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
                } else {
                    let movieViewController = self.storyboard?.instantiateViewControllerWithIdentifier(viewId) as? MovieBuilderViewController
                    movieViewController!.index = index
                    viewController = movieViewController
                }
                
                self.viewControllers.append(viewController!)
                index++
            }
        }
    }
    
    
    // MARK: Tab bar navigation button actions
    @IBAction func selectScene(sender: UIButton) {
        
    }
    
    
    //MARK: Page view controller delegate methods
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if viewController.isKindOfClass(IntroViewController) {
            let vc = viewController as! IntroViewController
            self.currentVC = vc.index - 1
        } else if viewController.isKindOfClass(SceneViewController) {
            let vc = viewController as! SceneViewController
            self.currentVC = vc.index - 1
        } else if viewController.isKindOfClass(MovieBuilderViewController) {
            let vc = viewController as! MovieBuilderViewController
            self.currentVC = vc.index - 1
        }
        
        if self.currentVC < 0 {
            return nil
        }
        
        return self.viewControllers[self.currentVC]
    }

    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if viewController.isKindOfClass(IntroViewController) {
            let vc = viewController as! IntroViewController
            self.currentVC = vc.index + 1
        } else if viewController.isKindOfClass(SceneViewController) {
            let vc = viewController as! SceneViewController
            self.currentVC = vc.index + 1
        } else if viewController.isKindOfClass(MovieBuilderViewController) {
            let vc = viewController as! MovieBuilderViewController
            self.currentVC = vc.index + 1
        }
        
        if self.currentVC == self.viewControllers.count {
            return nil
        }
        
        return self.viewControllers[self.currentVC]
    }
    
}

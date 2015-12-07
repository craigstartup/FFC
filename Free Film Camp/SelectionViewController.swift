//  assisted by http://swiftiostutorials.com/tutorial-custom-tabbar-storyboard/
//  SelectionViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 11/1/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit

class SelectionViewController: UIViewController, UIPageViewControllerDataSource {
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
    var currentVC = 1
    var startVC = true
    
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
        guard let initialViewController = self.storyboard?.instantiateViewControllerWithIdentifier("SceneViewController") as? SceneViewController else {return}
        initialViewController.sceneNumber = 0
        
        self.getViewControllers()
        
        self.pageViewController = pageViewController
        self.pageViewController.dataSource = self
        self.pageViewController.setViewControllers([initialViewController], direction: .Forward, animated: false, completion: nil)
        
        self.pageViewController.view.frame = self.viewsView.bounds
        self.viewsView.addSubview(self.pageViewController.view)
        self.addChildViewController(self.pageViewController)
        self.pageViewController.didMoveToParentViewController(self)
    }
    
    
    func getViewControllers() {
        for viewId in self.viewControllerIds {
            if viewId == "SceneViewController" {
                for var i = 0; i < MediaController.sharedMediaController.scenes.count; i++ {
                    let sceneViewController = self.storyboard?.instantiateViewControllerWithIdentifier(viewId) as? SceneViewController
                    sceneViewController?.sceneNumber = i
                    self.viewControllers.append(sceneViewController!)
                }
            } else {
                var viewController: UIViewController!
                
                if viewId == "IntroViewController" {
                    viewController = self.storyboard?.instantiateViewControllerWithIdentifier(viewId) as? IntroViewController
                } else {
                    viewController = self.storyboard?.instantiateViewControllerWithIdentifier(viewId) as? MovieBuilderViewController
                }
                
                self.viewControllers.append(viewController!)
            }
        }
    }
    
    
    // MARK: Tab bar navigation button actions
    @IBAction func selectScene(sender: UIButton) {
        
    }
    
    
    //MARK: Page view controller delegate methods
    func viewControllerAtIndex(index: Int) -> UIViewController? {
        if self.viewControllers.count == 0 || index >= self.viewControllers.count {
            return nil
        }
        
        return self.viewControllers[index]
    }
    
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if self.currentVC > self.viewControllers.count || self.currentVC < 0 {
        return nil
        }
        
        if startVC {
            currentVC--
        }
        
        let viewController = self.viewControllers[self.currentVC]
        
        if !startVC {
            currentVC--
        }
        return viewController
    }

    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if self.currentVC > self.viewControllers.count || self.currentVC < 0 {
            return nil
        }
        
        if startVC {
            currentVC++
        }
        
        let viewController = self.viewControllers[self.currentVC]
        
        if !startVC {
            currentVC++
        }
        
        return viewController
    }
}

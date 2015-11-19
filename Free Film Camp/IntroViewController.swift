//
//  IntroViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 11/19/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {

    @IBOutlet weak var introButton: UIButton!
    
    @IBOutlet weak var destroyIntroButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBarHidden = true
        
    }

    @IBAction func selectIntro(sender: UIButton) {
        
        
    }
    
    
    @IBAction func destroyIntro(sender: UIButton) {
        
        
    }
    
    
    @IBAction func previewIntro(sender: UIButton) {
        
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

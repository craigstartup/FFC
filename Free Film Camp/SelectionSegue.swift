//
//  SelectionSegue.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 11/1/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit

class SelectionSegue: UIStoryboardSegue {

//    override func perform() {
//        // set up source view of segue and destination view
//        let selectionView = self.sourceViewController as! SelectionViewController
//        let destinationView = self.destinationViewController as UIViewController
//        // remove any currently existing views from selection view.
//        for view in selectionView.viewsView.subviews as [UIView] {
//            view.removeFromSuperview()
//        }
//        // add destination view to selection view
//        selectionView.currentViewController = destinationView
//        selectionView.viewsView.addSubview(destinationView.view)
//        // make sure destination view resizes to selection view
//        selectionView.viewsView.translatesAutoresizingMaskIntoConstraints = false
//        destinationView.view.translatesAutoresizingMaskIntoConstraints = false
//        // add constraints for the added view
//        let horizontalConstraint = NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[v1]-0-|", options: .AlignAllTop, metrics: nil, views: ["v1": destinationView.view])
//        let verticalConstraint = NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[v1]-0-|", options: .AlignAllTop, metrics: nil, views: ["v1": destinationView.view])
//        NSLayoutConstraint.activateConstraints(horizontalConstraint)
//        NSLayoutConstraint.activateConstraints(verticalConstraint)
//        selectionView.viewsView.layoutIfNeeded()
//        destinationView.didMoveToParentViewController(selectionView)
//    }
}

//
//  Utilities.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 11/13/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import Foundation

struct ToolBox {
    
    func getDate() -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .LongStyle
        let date = dateFormatter.stringFromDate(NSDate())
        return date
    }
}
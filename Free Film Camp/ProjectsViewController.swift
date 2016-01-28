//
//  ProjectsViewController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 11/25/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import UIKit

class ProjectsViewController: UITableViewController {
    var projects = NSUserDefaults.standardUserDefaults().arrayForKey("projects")

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.allowsMultipleSelectionDuringEditing = false
    }
    
    // MARK: Action methods
    @IBAction func addProject(sender: UIBarButtonItem) {
        // TODO: Present alert with text field. After text is entered for name, have that alert present an action sheet that sets project template.
        
        
        // Present an alert veiw with text box to enter new project name, confirm button and cancel button.
        let addProjectView = UIAlertController(title: "Project Type", message: "Please choose a project type.", preferredStyle: .ActionSheet)
        
        let addNewProject1 = UIAlertAction(title: "1 scene", style: .Default) { (_) -> Void in
            // Capture project name and store it in array to populate table view.
            NSUserDefaults.standardUserDefaults().setObject(["intro":false,"music":true], forKey: MediaController.sharedMediaController.project!)
            MediaController.sharedMediaController.numberOfScenes = 1
            self.tableView.reloadData()
        }
        
        let addNewProject2 = UIAlertAction(title: "3 Scenes", style: .Default) { (_) -> Void in
            // Capture project name and store it in array to populate table view.
            NSUserDefaults.standardUserDefaults().setObject(["intro":false,"music":true], forKey: MediaController.sharedMediaController.project!)
            NSUserDefaults.standardUserDefaults().synchronize()
            MediaController.sharedMediaController.numberOfScenes = 3
            self.tableView.reloadData()
        }
        
        let addNewProject3 = UIAlertAction(title: "Intro & 3 Scenes", style: .Default) { (_) -> Void in
            // Capture project name and store it in array to populate table view.
            NSUserDefaults.standardUserDefaults().setObject(["intro":true,"music":true], forKey: MediaController.sharedMediaController.project!)
            NSUserDefaults.standardUserDefaults().synchronize()
            MediaController.sharedMediaController.numberOfScenes = 3
            self.tableView.reloadData()
        }
        
        let nameProjectView = UIAlertController(title: "Name A New Project", message: "Please enter a project name.", preferredStyle: .Alert)
        
        let confirmName = UIAlertAction(title: "Yes", style: .Default) { (_) -> Void in
            let projectTextField = nameProjectView.textFields![0] as UITextField
            self.projects!.append(projectTextField.text!)
            NSUserDefaults.standardUserDefaults().setObject(self.projects, forKey: "projects")
            NSUserDefaults.standardUserDefaults().setObject(projectTextField.text, forKey: "currentProject")
            NSUserDefaults.standardUserDefaults().synchronize()
            // Add directory for project
            self.createProjectDirectory(projectTextField.text)
            MediaController.sharedMediaController.project = projectTextField.text!
            self.presentViewController(addProjectView, animated: true, completion: nil)
        }
        
        let cancelName = UIAlertAction(title: "No", style: .Destructive, handler: nil)
        
        nameProjectView.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Project Name"
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue(), usingBlock: { (notification) -> Void in
                confirmName.enabled = textField.text != ""
            })
        }
        
        nameProjectView.addAction(confirmName)
        nameProjectView.addAction(cancelName)
        
        addProjectView.addAction(addNewProject1)
        addProjectView.addAction(addNewProject2)
        addProjectView.addAction(addNewProject3)
        
        self.presentViewController(nameProjectView, animated: true, completion: nil)
    }
    
    // MARK: Table view methods
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.projects!.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("projectCell")
        cell?.textLabel!.text = self.projects![indexPath.row] as? String
        return cell!
    }
    
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let currentProject = NSUserDefaults.standardUserDefaults().stringForKey("currentProject")
        
        if cell.textLabel!.text == currentProject {
            cell.setSelected(true, animated: false)
        }
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        NSUserDefaults.standardUserDefaults().setObject(self.projects![indexPath.row], forKey: "currentProject")
        NSUserDefaults.standardUserDefaults().synchronize()
        MediaController.sharedMediaController.project = self.projects![indexPath.row] as? String
        self.tableView.reloadData()
        NSNotificationCenter.defaultCenter().postNotificationName(MediaController.Notifications.projectSelected, object: self)
    }
    
    
    // MARK: Table veiw editing
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if self.projects![indexPath.row] as? String == NSUserDefaults.standardUserDefaults().stringForKey("currentProject") {
                let currentProject = self.projects?.first
                NSUserDefaults.standardUserDefaults().setObject(currentProject, forKey: "currentProject")
                MediaController.sharedMediaController.project = self.projects?.first! as? String
            }
            
            destroyProject(self.projects![indexPath.row] as! String)
            
            self.projects?.removeAtIndex(indexPath.row)
            NSUserDefaults.standardUserDefaults().setObject(self.projects, forKey: "projects")
            NSUserDefaults.standardUserDefaults().synchronize()
            self.tableView.reloadData()
        }
    }
    
    // MARK: Project directory methods
    func createProjectDirectory(project: String!) {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first
        let projectDirectory = documentsDirectory?.stringByAppendingString("/\(project)")
        let fileManager = NSFileManager.defaultManager()
        
        if !fileManager.fileExistsAtPath(projectDirectory!) {
            do {
                try fileManager.createDirectoryAtPath(projectDirectory!, withIntermediateDirectories: true, attributes: nil)
            } catch let dirError as NSError {
                print(dirError.localizedDescription)
            }
        } else {
            print("Project name already exists")
        }
    }
    
    
    func destroyProject(project: String!) {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first
        let projectDirectory = documentsDirectory?.stringByAppendingString("/\(project)")
        let fileManager = NSFileManager.defaultManager()
        
        do {
            try fileManager.removeItemAtPath(projectDirectory!)
        } catch let directoryDestroyError as NSError {
            print(directoryDestroyError.localizedDescription)
        }
    }
    
    // MARK: Alert Views
}

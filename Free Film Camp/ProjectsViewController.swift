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

    @IBAction func addProject(sender: UIBarButtonItem) {
        // Present an alert veiw with text box to enter new project name, confirm button and cancel button.
        let addProjectView = UIAlertController(title: "Add Project", message: "Please enter a project name.", preferredStyle: .Alert)
        let addNewProject = UIAlertAction(title: "Create Project", style: .Default) { (_) -> Void in
            // Capture project name and store it in array to populate table view.
            let projectTextField = addProjectView.textFields![0] as UITextField
            self.projects!.append(projectTextField.text!)
            NSUserDefaults.standardUserDefaults().setObject(self.projects, forKey: "projects")
            NSUserDefaults.standardUserDefaults().setObject(projectTextField.text, forKey: "currentProject")
            NSUserDefaults.standardUserDefaults().synchronize()
            MediaController.sharedMediaController.project = projectTextField.text!
            MediaController.sharedMediaController.scenes = MediaController.sharedMediaController.loadScenes()!
            self.tableView.reloadData()
            // Add directory for project
            self.createProjectDirectory(projectTextField.text)
        }
        addNewProject.enabled = false
        
        let cancel = UIAlertAction(title: "Cancel", style: .Destructive) { (_) -> Void in }
        addProjectView.addTextFieldWithConfigurationHandler { (textField) -> Void in
            textField.placeholder = "Project Name"
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue(), usingBlock: { (notification) -> Void in
                addNewProject.enabled = textField.text != ""
            })
        }
        
        addProjectView.addAction(cancel)
        addProjectView.addAction(addNewProject)
        
        self.presentViewController(addProjectView, animated: true, completion: nil)
    }

    
    @IBAction func switchMediaToShow(sender: UISwitch) {
        
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
        MediaController.sharedMediaController.scenes = MediaController.sharedMediaController.loadScenes()!
        self.tableView.reloadData()
    }
    
    
    // MARK: Table veiw editing
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            if self.projects![indexPath.row] as? String == NSUserDefaults.standardUserDefaults().stringForKey("currentProject") {
                let currentProject = self.projects?.first
                NSUserDefaults.standardUserDefaults().setObject(currentProject, forKey: "currentProject")
                MediaController.sharedMediaController.project = self.projects?.first! as? String
                MediaController.sharedMediaController.scenes = MediaController.sharedMediaController.loadScenes()!
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
}

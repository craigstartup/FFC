//
//  AppDelegate.swift
//  Film Camp
//
//  Created by Eric Mentele on 10/4/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import UIKit
import CoreData
import Photos
import SwiftyDropbox

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        if let authResult = Dropbox.handleRedirectURL(url) {
            switch authResult {
            case .Success(let token):
                print("Success! User is logged into Dropbox with token: \(token)")
                DropboxAuthManager.sharedAuthManager.storeAccessToken(token)
            case .Error(let error, let description):
                print("Error \(error): \(description)")
            }
        }
        return false
    }
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        Dropbox.setupWithAppKey("4p67b3c6hmo9s1n")
        
        // Create user projects name storage.
        if let _ = NSUserDefaults.standardUserDefaults().arrayForKey("projects") {
        } else {
            let currentProject = "Default Project"
            let projects = [currentProject]
            NSUserDefaults.standardUserDefaults().setObject(projects, forKey: "projects")
            NSUserDefaults.standardUserDefaults().setObject(currentProject, forKey: "currentProject")
            NSUserDefaults.standardUserDefaults().setObject(["intro":false,"music":false], forKey: currentProject)
            NSUserDefaults.standardUserDefaults().synchronize()
            
            // Create a file directory for the default project
            let documentsDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first
            let projectDirectory = documentsDirectory?.stringByAppendingString("/\(currentProject)")
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
        
        
        
        let moviesFetchOptions = PHFetchOptions()
        let clipsFetchOptions = PHFetchOptions()
        var clipsAlbum: PHFetchResult!
        var moviesAlbum: PHFetchResult!
        let clipsAlbumTitle = "Film Camp Clips"
        let moviesAlbumTitle = "Film Camp Movies"
        
        PHPhotoLibrary.requestAuthorization { (status) -> Void in
            if status == PHAuthorizationStatus.Authorized {
                // set up album for recorded clips
                clipsFetchOptions.predicate = NSPredicate(format: "title = %@", clipsAlbumTitle)
                clipsAlbum = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: clipsFetchOptions)
                
                if let _: AnyObject = clipsAlbum.firstObject {
                    
                } else {
                    
                    PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                        PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(clipsAlbumTitle)
                        }) { (success: Bool, error: NSError?) -> Void in
                            if !success {
                                print(error!.localizedDescription)
                            }
                    }
                }

                // set up album for recorded movies
                moviesFetchOptions.predicate = NSPredicate(format: "title = %@", moviesAlbumTitle)
                moviesAlbum = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: moviesFetchOptions)
                
                if let _: AnyObject = moviesAlbum.firstObject {
                    
                } else {
                    
                    PHPhotoLibrary.sharedPhotoLibrary().performChanges({ () -> Void in
                        PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle(moviesAlbumTitle)
                        }) { (success: Bool, error: NSError?) -> Void in
                            if !success {
                                print(error!.localizedDescription)
                            }
                    }
                }
            }
        }

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.ericmentele.Free_Film_Camp" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Free_Film_Camp", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }

}


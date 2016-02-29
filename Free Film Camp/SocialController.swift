//
//  SocialController.swift
//  Film Camp
//
//  Created by Eric Mentele on 12/28/15.
//  Copyright © 2015 Craig Swanson. All rights reserved.
//

import Foundation
import Social
import Accounts

class SocialController {
    let accounts = ACAccountStore()
    let accountTypeFB: ACAccountType
    var facebookAccount: ACAccount!
    
    init() {
        self.accountTypeFB = self.accounts.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
        self.checkFBAccountAuth()
    }
    
    func checkFBAccountAuth() {
        if let fbaccounts = accounts.accountsWithAccountType(accountTypeFB) {
            if fbaccounts.count > 0 {
                let facebookAccount = fbaccounts[0] as! ACAccount
                self.facebookAccount = facebookAccount
                
                if facebookAccount.credential == nil {
                    self.accounts.renewCredentialsForAccount(facebookAccount, completion: { (result, error) -> Void in
                        if error != nil {
                            print(error.localizedDescription)
                        }
                    })
                }
            }
        }
    }
    
    func setupAccounts(withMovieToSend movie: NSURL?) {
        // FACEBOOK READ AND WRITE
        let readOptions = [ACFacebookAppIdKey:"318605501597030", ACFacebookPermissionsKey:["email"], ACFacebookAudienceKey:ACFacebookAudienceOnlyMe]
        let writeOptions = [
            ACFacebookAppIdKey:"318605501597030",
            ACFacebookPermissionsKey:["publish_actions"],
            ACFacebookAudienceKey:ACFacebookAudienceFriends,
            ACFacebookAudienceKey:ACFacebookAudienceEveryone,
            ACFacebookAudienceKey:ACFacebookAudienceOnlyMe]
        
        self.accounts.requestAccessToAccountsWithType(self.accountTypeFB, options: readOptions as [NSObject:AnyObject]) {[unowned self](granted, error) -> Void in
            if granted {
                let facebookAccounts = [self.accounts.accountsWithAccountType(self.accountTypeFB)]
                
                if facebookAccounts.count > 0 {
                    print("GOT FACEBOOK ACCOUNT READ")
                }
            } else {
                print("Facebook access denied.")
                if error != nil {
                    print(error.localizedDescription)
                }
            }
        }

        self.accounts.requestAccessToAccountsWithType(self.accountTypeFB, options: writeOptions as [NSObject:AnyObject]) {[unowned self] (granted, error) -> Void in
            if granted {
                let facebookAccounts = [self.accounts.accountsWithAccountType(self.accountTypeFB)]
                
                if facebookAccounts.count > 0 {
                    print("GOT FACEBOOK ACCOUNT WRITE")
                    if movie != nil {
                        self.postMovieToFacebook(movie!)
                    }
                }
            } else {
                print("Facebook access denied.")
                
                if error != nil {
                    print(error.localizedDescription)
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    NSNotificationCenter.defaultCenter().postNotificationName(MediaController.Notifications.noSocialSetup, object: self)
                })
            }
        }
    }
    
    func postMovieToFacebook(movie: NSURL) {
        guard let facebookAccount = self.facebookAccount else {
            print("FACEBOOK ACCOUNT FAILED")
            self.setupAccounts(withMovieToSend: movie)
            return
        }
        
        let videoURL = NSURL(string: "https://graph-video.facebook.com/me/videos")
        let movieData = NSData(contentsOfURL: movie)
        let parameters = ["access_token": facebookAccount.credential.oauthToken, "title": "My Movie", "description":"Created with Film Camp on iOS"]
        
        let uploadRequest = SLRequest(
            forServiceType: SLServiceTypeFacebook,
            requestMethod: SLRequestMethod.POST,
            URL: videoURL,
            parameters: parameters)
        
        uploadRequest.addMultipartData(
            movieData,
            withName: "source",
            type: "video/quicktime",
            filename: movie.absoluteString)
        
        uploadRequest.account = facebookAccount
        print("Begin upload")
        NSNotificationCenter.defaultCenter().postNotificationName(MediaController.Notifications.sharingComplete, object: self)
        uploadRequest.performRequestWithHandler { (dataResponse, urlResponse, error) -> Void in
            if (error != nil) {
                print(error.localizedDescription)
                NSNotificationCenter.defaultCenter().postNotificationName(MediaController.Notifications.uploadFailed, object: self)
            } else {
                print(dataResponse.description)
                print(urlResponse.description)
                NSNotificationCenter.defaultCenter().postNotificationName(MediaController.Notifications.uploadComplete, object: self)
            }
        }
    }
}
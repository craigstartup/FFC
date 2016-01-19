//
//  SocialController.swift
//  Free Film Camp
//
//  Created by Eric Mentele on 12/28/15.
//  Copyright © 2015 Eric Mentele. All rights reserved.
//

import Foundation
import Social
import Accounts

class SocialController {
    let accounts = ACAccountStore()
    var accountTypeFB: ACAccountType
    var accountTypeTwit: ACAccountType
    
    init() {
        self.accountTypeFB = self.accounts.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierFacebook)
        self.accountTypeTwit = self.accounts.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        self.setupAccounts()
    }
    
    func setupAccounts() {
        // TWITTER
        self.accounts.requestAccessToAccountsWithType(self.accountTypeTwit, options: nil) {(granted, error) -> Void in
            if granted {
                print("Twitter Account!")
            } else {
                print("Twitter access denied.")
            }
        }
        // FACEBOOK READ AND WRITE
        let readOptions = [ACFacebookAppIdKey:"318605501597030", ACFacebookPermissionsKey:["email"], ACFacebookAudienceKey:ACFacebookAudienceOnlyMe]
        let writeOptions = [
            ACFacebookAppIdKey:"318605501597030",
            ACFacebookPermissionsKey:["publish_actions"],
            ACFacebookAudienceKey:ACFacebookAudienceFriends,
            ACFacebookAudienceKey:ACFacebookAudienceEveryone,
            ACFacebookAudienceKey:ACFacebookAudienceOnlyMe]
        
        self.accounts.requestAccessToAccountsWithType(self.accountTypeFB, options: readOptions as [NSObject:AnyObject]) {[unowned self] (granted, error) -> Void in
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
                }
            } else {
                print("Facebook access denied.")
                if error != nil {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func postMovieToFacebook(movie: NSURL) {
        guard let facebookAccount = self.accounts.accountsWithAccountType(self.accountTypeFB)[0] as? ACAccount else {
            print("FACEBOOK ACCOUNT FAILED")
            return
        }
        
        if facebookAccount.credential == nil {
            self.accounts.renewCredentialsForAccount(facebookAccount, completion: { (result, error) -> Void in
                if error != nil {
                    print(error.localizedDescription)
                }
            })
        }
        
        let videoURL = NSURL(string: "https://graph-video.facebook.com/me/videos")
        let movieData = NSData(contentsOfURL: movie)
        let parameters = ["access_token": facebookAccount.credential.oauthToken, "title": "My Movie", "description":"test video"]
        
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
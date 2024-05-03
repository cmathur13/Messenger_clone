//
//  AppDelegate.swift
//  Messenger
//
//  Created by Ritik Srivastava on 11/10/20.
//  Copyright © 2020 Ritik Srivastava. All rights reserved.
//

// Swift
//
// AppDelegate.swift

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate  ,GIDSignInDelegate {
        
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        FirebaseApp.configure()
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self

        return true
    }
          
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {

        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )

        return GIDSignIn.sharedInstance().handle(url)
        
    }


    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            print("failed to sigIn by Google")
            return
        }
        
        guard let user = user else { return }
        guard let email = user.profile.email else {return}
        guard let username = user.profile.name else { return }
        
//        print(username , email)
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,accessToken: authentication.accessToken)
        
        Auth.auth().signIn(with: credential) { (result, error) in
    
            guard result != nil , error == nil else {
                print("You cannot sigin in due to MFA or other problem")
                return
            }
            
            // it is used to chache the username and email locally with this key
            UserDefaults.standard.set(username, forKey: "username")
            UserDefaults.standard.set(email, forKey: "email")

            print("Scuessfully signed with Google")
            
            let chatUser = ChatAppUser(username: username, email: email)
            DatabaseManager.shared.insertUser(with: chatUser , completion: { sucess in
                if sucess {
                    
                    if user.profile.hasImage {
                        guard let url = user.profile.imageURL(withDimension: 200) else{return}
                        print(url)
                        URLSession.shared.dataTask(with: url, completionHandler: { (data, _ , _) in
                            print("image upload sucesfully")
                            guard let data = data else { return }
                
                            let filename = chatUser.profileImageFileName
                            print(filename)
                            StorageManager.shared.uploadProfilePicture(with: data, filename: filename) { (result) in
                                switch result {
                                case .failure(let error):
                                    print(error)
                                case .success(let downloadUrl):
                                    UserDefaults.standard.set(downloadUrl, forKey: "profile_pic")
                                    print(downloadUrl)
                                }
                            }
                            
                            }).resume()
                    }
                    
                    else{
                        print("cannot found image")
                    }
                    
                }else{
                    print("cannot upload image")
                }
            })
            
            NotificationCenter.default.post(name: Notification.Name.didLogInNotificationByGoogle , object : nil)
        }
        
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google user disconnected")
    }
    
}

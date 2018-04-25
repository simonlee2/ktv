//
//  AppDelegate.swift
//  Cashbox
//
//  Created by Shao-Ping Lee on 3/6/18.
//  Copyright © 2018 Simon Lee. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var auth = SPTAuth()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        auth.redirectURL = URL(string: "Cashbox://returnAfterLogin")
        auth.sessionUserDefaultsKey = "current session"
        
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if auth.canHandle(auth.redirectURL) {
            auth.handleAuthCallback(withTriggeredAuthURL: url, callback: { (error, session) in
                if let error = error {
                    print(error)
                }
                
                let userDefaults = UserDefaults.standard
                let sessionData = NSKeyedArchiver.archivedData(withRootObject: session as Any)
                userDefaults.set(sessionData, forKey: "SpotifySession")
                userDefaults.synchronize()
                NotificationCenter.default.post(name: Notification.Name(rawValue: "loginSuccessful"), object: nil)
            })
            return true
        }
        
        return false
    }


}


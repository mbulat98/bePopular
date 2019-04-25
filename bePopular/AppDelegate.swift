//
//  AppDelegate.swift
//  CharityGod
//
//  Created by Bulat, Maksim on 17/04/2019.
//  Copyright © 2019 Bulat, Maksim. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import FacebookCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let viewController = LoginViewController.storyboardInstance()
        let navigationController = UINavigationController(rootViewController: viewController)

        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()

        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let handled = SDKApplicationDelegate.shared.application(app, open: url, options: options)
        return GIDSignIn.sharedInstance().handle(url,
                                                 sourceApplication:options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
                                                 annotation: [:]) || handled
    }
}


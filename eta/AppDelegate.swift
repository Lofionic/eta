//
//  AppDelegate.swift
//  eta
//
//  Created by Chris Rivers on 03/03/2021.
//

import UIKit

import Firebase


@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let window = UIWindow(frame: UIScreen.main.bounds)
    var coordinator: CoreCoordinator!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
		
        coordinator = CoreCoordinator()
        window.rootViewController = coordinator.rootViewController
        window.makeKeyAndVisible()
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("Application opening url: \(url)")
        
        guard url.host == "session" else {
            return false
        }
        
        let sessionIdentifier = url.lastPathComponent
        PendingSessionController.shared.addPendingSession(sessionIdentifier)
        
        return true
    }
}

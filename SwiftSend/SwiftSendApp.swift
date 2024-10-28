//
//  SwiftSendApp.swift
//  SwiftSend
//
//  Created by Brody on 9/4/24.
//

import SwiftUI
import Wavelike

@main
struct SwiftSendApp: App {
    
    init() {
        Wavelike.set(appId: "6717e6a28c0efd2ae755452d")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

//
//@objc
//class AppDelegate: NSObject, UIApplicationDelegate {
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        
//        
//
//        
//
//        return true
//    }
//}

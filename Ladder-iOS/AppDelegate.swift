//
//  AppDelegate.swift
//  Ladder
//
//  Created by Aofei Sheng on 2018/3/23.
//  Copyright © 2018 Aofei Sheng. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	let window = UIWindow(frame: UIScreen.main.bounds)

	func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
//        let profileMgr = ServerProfileManager.instance
//        if profileMgr.activeProfileId == nil &&
//            profileMgr.profiles.count > 0{
//            if profileMgr.profiles[0].isValid(){
//                profileMgr.setActiveProfiledId(profileMgr.profiles[0].uuid)
//            }
//        }
        
		window.backgroundColor = .white
		window.rootViewController = UINavigationController(rootViewController: ServerListController())
		window.makeKeyAndVisible()

		return true
	}
}

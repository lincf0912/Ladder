//
//  AppDelegate.swift
//  Ladder-mac
//
//  Created by TsanFeng Lam on 2019/2/12.
//  Copyright © 2019 Aofei Sheng. All rights reserved.
//

import Cocoa
import NetworkExtension

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let menu = MainMenu()
    
    var currentServer: ServerProfile? = nil
    var serverList: Array<ServerProfile> = []
    
    let manager: NEVPNManager = NEVPNManager.shared()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
    
    
}

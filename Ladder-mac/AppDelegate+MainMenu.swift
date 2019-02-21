//
//  AppDelegate+MainMenu.swift
//  Ladder-mac
//
//  Created by TsanFeng Lam on 2019/2/19.
//  Copyright © 2019 Aofei Sheng. All rights reserved.
//

import Cocoa

// MARK: - MainMenuProtocol

extension AppDelegate {
    
    @objc func mm_connectVPN(_ item: NSMenuItem) {
        connectVPN()
    }
    
    @objc func mm_chooseVPN(_ item: NSMenuItem) {
        currentServer = item.representedObject as? ServerProfile
        mm_connectVPN(item)
    }
    
    @objc func mm_scanQRCodeSubmenu(_ item: NSMenuItem) {
        let urls: [URL] = ScanQRCodeOnScreen()
        for url in urls {
            if let profile = ServerProfile(url: url) {
                serverList.append(profile)
            }
        }
        menu.updateServerMenu(serverList)
    }
    
    
    @objc func mm_sendFeedback(_ item: NSMenuItem) {
        let service = NSSharingService(named: NSSharingService.Name.composeEmail)
        service?.recipients = ["dayflyking@163.com"]
        service?.subject = "Ladder-mac Feedback"
        service?.perform(withItems: ["Write Your Feedback, Thanks"])
        
        NSWorkspace.shared.launchApplication("Mail")
    }
    
    @objc func mm_terminate(_ item: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
}

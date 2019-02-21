//
//  MainMenu.swift
//  Ladder-mac
//
//  Created by TsanFeng Lam on 2019/2/12.
//  Copyright © 2019 Aofei Sheng. All rights reserved.
//

import Cocoa

let serverTag = 101

public protocol MainMenuProtocol : NSObjectProtocol {
    
    func mainMenuQuitApp(_ item : NSMenuItem)
}

class MainMenu: NSObject {
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    
    override init() {
        super.init()
        buildUI()
    }
    
    private func buildUI() {
        
        if let button = statusItem.button {
            button.image = NSImage(named: "MenuIcon")
            button.imagePosition = .imageLeft
            button.title = ""
        }
        
        let menu_main = NSMenu()
        menu_main.autoenablesItems = false;
        
        menu_main.title = "Main"
        
        let vpnStatusMenuItem = NSMenuItem(title: NSLocalizedString("VPNStatus", comment: "VPN Status"), action: nil, keyEquivalent: "")
        vpnStatusMenuItem.isEnabled = false;
        let vpnConnectMenuItem = NSMenuItem(title: NSLocalizedString("ConnectVPN", comment: "connect VPN"), action:#selector(AppDelegate.mm_connectVPN(_:)), keyEquivalent: "")
        
        menu_main.addItem(vpnStatusMenuItem)
        menu_main.addItem(vpnConnectMenuItem)
        menu_main.addItem(NSMenuItem.separator())
        
        let serverSubmenu = NSMenuItem(title: NSLocalizedString("Server", comment: "choose VPN"), action: nil, keyEquivalent: "")
        serverSubmenu.tag = serverTag
        serverSubmenu.submenu = NSMenu()
        serverSubmenu.isEnabled = false;
        menu_main.addItem(serverSubmenu)
        
        let scanQRCodeSubmenu = NSMenuItem(title: NSLocalizedString("Scan QR Code From Screen", comment: "Scan QR Code From Screen"), action:#selector(AppDelegate.mm_scanQRCodeSubmenu(_:)), keyEquivalent: "")
        menu_main.addItem(scanQRCodeSubmenu)
        
        menu_main.addItem(NSMenuItem.separator())
        
        let contactMeSubmenu = NSMenuItem(title: NSLocalizedString("SendFeedback", comment: "send feedback"), action:#selector(AppDelegate.mm_sendFeedback(_:)), keyEquivalent: "")
        menu_main.addItem(contactMeSubmenu)
        
        menu_main.addItem(NSMenuItem.separator())
        
        menu_main.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: "quit"), action: #selector(AppDelegate.mm_terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu_main
    }
    
    func updateServerMenu(_ list: Array<ServerProfile>) {
        
        let menu = NSMenu()
        
        for server in list {
            let item = NSMenuItem(title: server.title(), action: #selector(AppDelegate.mm_chooseVPN(_:)), keyEquivalent: "")
            item.representedObject = server
            menu.addItem(item)
        }
        
        let serverSubmenu = statusItem.menu?.item(withTag: serverTag)
        serverSubmenu?.submenu = menu
        
        serverSubmenu?.isEnabled = (list.count>0);
        
    }
}

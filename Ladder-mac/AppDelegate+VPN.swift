//
//  AppDelegate+VPN.swift
//  Ladder-mac
//
//  Created by TsanFeng Lam on 2019/2/19.
//  Copyright © 2019 Aofei Sheng. All rights reserved.
//

import Cocoa
import NetworkExtension

extension AppDelegate {
    
    func connectVPN(){
        self.manager.connection.stopVPNTunnel()
        Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(AppDelegate._connectVPN), userInfo: nil, repeats: false)
    }
    
    @objc func _connectVPN(){
        if self.currentServer == nil {
            return
        }
        
        self.manager.loadFromPreferences { [unowned self] (error: Error?) -> Void in
            if error != nil{
                print("load error: \(String(describing: error))")
            }else{
                let vpnProtocol = NEVPNProtocolIKEv2()
//                vpnProtocol.username = loginUserName
//                vpnProtocol.passwordReference = password
//                vpnProtocol.serverAddress = currentServer!.ip
//                vpnProtocol.authenticationMethod = .none
//                vpnProtocol.remoteIdentifier = currentServer!.remote_id
//                vpnProtocol.localIdentifier = loginUserName
//                vpnProtocol.useExtendedAuthentication = true
//                vpnProtocol.disconnectOnSleep = false
                self.manager.isEnabled = true
                self.manager.protocolConfiguration = vpnProtocol
                self.manager.saveToPreferences(completionHandler: { (error: Error?) -> Void in
                    if error != nil{
                        print("save error: \(String(describing: error))")
                    }else{
                        do{
                            try self.manager.connection.startVPNTunnel()
                        }catch{
                            print("connect error: \(String(describing: error))")
                        }
                    }
                })
            }
        }
    }
    
    func disconnectVPN(){
        self.manager.connection.stopVPNTunnel()
    }
    
}

//
//  ConfigViewController.swift
//  Ladder
//
//  Created by TsanFeng Lam on 2018/9/20.
//  Copyright © 2018年 Aofei Sheng. All rights reserved.
//

import UIKit
import Eureka
import Alamofire
import NetworkExtension
import SafariServices

class ConfigViewController: FormViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private var profile: ServerProfile? = nil
    
    
    convenience init(profile: ServerProfile) {
        self.init()
        self.profile = profile
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("ServerConfig", comment: "")

        
        form
            +++ Section(header: NSLocalizedString("General", comment: ""), footer: "") { section in
                section.tag = "General"
                section.header?.height = { 30 }
                section.footer?.height = { .leastNonzeroMagnitude }
            }
            <<< SwitchRow { row in
                row.tag = "General - Hide VPN Icon"
                row.title = NSLocalizedString("Hide VPN Icon", comment: "")
                row.value = profile?.hideVPNIcon
                }.onChange({ (row) in
                    self.profile?.hideVPNIcon = row.value ?? false
                })
            <<< URLRow { row in
                row.tag = "General - PAC URL"
                row.title = "PAC URL"
                row.placeholder = NSLocalizedString("Enter PAC URL here", comment: "")
                row.value = URL(string: profile!.PAC_URL)
                
                row.add(rule: RuleRequired(msg: NSLocalizedString("Please enter a PAC URL.", comment: "")))
                row.add(rule: RuleURL(allowsEmpty: false, requiresProtocol: true, msg: NSLocalizedString("Please enter a valid PAC URL.", comment: "")))
                }.onChange({ (row) in
                    self.profile?.PAC_URL = row.value?.absoluteString ?? ""
                    })
            <<< IntRow { row in
                row.tag = "General - PAC Max Age"
                row.title = NSLocalizedString("PAC Max Age", comment: "")
                row.placeholder = NSLocalizedString("Enter PAC max age here", comment: "")
                row.value = Int(profile!.PAC_Max_Age)
                row.formatter = NumberFormatter()
                
                row.add(rule: RuleRequired(msg: NSLocalizedString("Please enter a PAC max age.", comment: "")))
                row.add(rule: RuleGreaterOrEqualThan(min: 0, msg: NSLocalizedString("PAC max age must greater than or equal to 0.", comment: "")))
                row.add(rule: RuleSmallerOrEqualThan(max: 86400, msg: NSLocalizedString("PAC max age must smaller than or equal to 86400.", comment: "")))
                }.onChange({ (row) in
                    self.profile?.PAC_Max_Age = uint_fast16_t(row.value ?? 0)
                })
            
            +++ Section(header: NSLocalizedString("Shadowsocks", comment: ""), footer: "") { section in
                section.tag = "Shadowsocks"
                section.header?.height = { 30 }
                section.footer?.height = { .leastNonzeroMagnitude }
            }
            <<< TextRow { row in
                row.tag = "Shadowsocks - Server Address"
                row.title = NSLocalizedString("Server Address", comment: "")
                row.placeholder = NSLocalizedString("Enter server address here", comment: "")
                if let host = profile?.serverHost {
                    row.value = host
                }
                row.cell.textField.keyboardType = .asciiCapable
                row.cell.textField.autocapitalizationType = .none
                
                row.add(rule: RuleRequired(msg: NSLocalizedString("Please enter a Shadowsocks server address.", comment: "")))
                }.onChange({ (row) in
                    self.profile?.serverHost = row.value ?? ""
                })
            <<< IntRow { row in
                row.tag = "Shadowsocks - Server Port"
                row.title = NSLocalizedString("Server Port", comment: "")
                row.placeholder = NSLocalizedString("Enter server port here", comment: "")
                if let port = profile?.serverPort {
                    row.value = Int(port)
                }
                row.formatter = NumberFormatter()
                
                row.add(rule: RuleRequired(msg: NSLocalizedString("Please enter a Shadowsocks server port.", comment: "")))
                row.add(rule: RuleGreaterOrEqualThan(min: 0, msg: NSLocalizedString("Shadowsocks server port must greater than or equal to 0.", comment: "")))
                row.add(rule: RuleSmallerOrEqualThan(max: 65535, msg: NSLocalizedString("Shadowsocks server port must smaller than or equal to 65535.", comment: "")))
                }.onChange({ (row) in
                    self.profile?.serverPort = uint_fast16_t(row.value ?? 0)
                })
            <<< TextRow { row in
                row.tag = "Shadowsocks - Local Address"
                row.title = NSLocalizedString("Local Address", comment: "")
                row.placeholder = NSLocalizedString("Enter local address here", comment: "")
                row.value = profile!.localHost
                row.cell.textField.keyboardType = .asciiCapable
                row.cell.textField.autocapitalizationType = .none
                
                row.add(rule: RuleRequired(msg: NSLocalizedString("Please enter a Shadowsocks local address.", comment: "")))
                }.onChange({ (row) in
                    self.profile?.localHost = row.value ?? ""
                })
            <<< IntRow { row in
                row.tag = "Shadowsocks - Local Port"
                row.title = NSLocalizedString("Local Port", comment: "")
                row.placeholder = NSLocalizedString("Enter local port here", comment: "")
                row.value = Int(profile!.localPort)
                row.formatter = NumberFormatter()
                
                row.add(rule: RuleRequired(msg: NSLocalizedString("Please enter a Shadowsocks local port.", comment: "")))
                row.add(rule: RuleGreaterOrEqualThan(min: 0, msg: NSLocalizedString("Shadowsocks local port must greater than or equal to 0.", comment: "")))
                row.add(rule: RuleSmallerOrEqualThan(max: 65535, msg: NSLocalizedString("Shadowsocks local port must smaller than or equal to 65535.", comment: "")))
                }.onChange({ (row) in
                    self.profile?.localPort = uint_fast16_t(row.value ?? 0)
                })
            <<< PasswordRow { row in
                row.tag = "Shadowsocks - Password"
                row.title = NSLocalizedString("Password", comment: "")
                row.placeholder = NSLocalizedString("Enter password here", comment: "")
                if let password = profile?.password {
                    row.value = password
                }
                row.add(rule: RuleRequired(msg: NSLocalizedString("Please enter a Shadowsocks password.", comment: "")))
                }.cellSetup({ (cell, row) in
                    cell.textField.isEnabled = false
                })
            <<< ActionSheetRow<String> { row in
                row.tag = "Shadowsocks - Method"
                row.title = NSLocalizedString("Method", comment: "")
                row.selectorTitle = NSLocalizedString("Shadowsocks Method", comment: "")
                let options = ["AES-128-CFB", "AES-192-CFB", "AES-256-CFB", "ChaCha20", "Salsa20", "RC4-MD5", "chacha20-ietf"] as [String]
                row.options = options
                if let method = profile?.method {
                    for option in options {
                        if option.lowercased() == method.lowercased() {
                            row.value = option
                            break
                        }
                    }
                } else {
                    row.value = "AES-256-CFB"
                }
                
                row.cell.detailTextLabel?.textColor = .black
                }.onChange({ (row) in
                    self.profile?.method = row.value ?? ""
                })
            
            +++ Section(header: "", footer: "") { section in
                section.tag = "Configure"
                section.header?.height = { 30 }
                section.footer?.height = { .leastNonzeroMagnitude }
            }
            <<< ButtonRow { row in
                row.tag = "Configure - Configure"
                row.title = NSLocalizedString("Configure", comment: "")
                }.onCellSelection { _, _ in
                    let configuringAlertController = UIAlertController(
                        title: NSLocalizedString("Configuring...", comment: ""),
                        message: nil,
                        preferredStyle: .alert
                    )
                    self.present(configuringAlertController, animated: true)
                    
                    var providerManager = NETunnelProviderManager()
                    providerManager.connection.stopVPNTunnel()
                    
                    if let reachable = Alamofire.NetworkReachabilityManager(host: "8.8.8.8")?.isReachable, !reachable {
                        let alertController = UIAlertController(
                            title: NSLocalizedString("Configuration Failed", comment: ""),
                            message: NSLocalizedString("Please check your network settings and allow Ladder to access your wireless data in the system's \"Settings - Cellular\" option (remember to check the \"WLAN & Cellular Data\").", comment: ""),
                            preferredStyle: .alert
                        )
                        if let openSettingsURL = URL(string: UIApplication.openSettingsURLString) {
                            alertController.addAction(UIAlertAction(
                                title: NSLocalizedString("Settings", comment: ""),
                                style: .default,
                                handler: { _ in
                                    UIApplication.shared.openURL(openSettingsURL)
                            }
                            ))
                        }
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
                        configuringAlertController.dismiss(animated: true) {
                            self.present(alertController, animated: true)
                        }
                        return
                    } else if let firstValidationError = self.form.validate().first {
                        let alertController = UIAlertController(
                            title: NSLocalizedString("Configuration Failed", comment: ""),
                            message: firstValidationError.msg,
                            preferredStyle: .alert
                        )
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
                        configuringAlertController.dismiss(animated: true) {
                            self.present(alertController, animated: true)
                        }
                        return
                    }
                    
                    let generalHideVPNIcon = (self.form.rowBy(tag: "General - Hide VPN Icon") as! SwitchRow).value!
                    let generalPACURL = (self.form.rowBy(tag: "General - PAC URL") as! URLRow).value!
                    let generalPACMaxAge = (self.form.rowBy(tag: "General - PAC Max Age") as! IntRow).value!
                    let shadowsocksServerAddress = (self.form.rowBy(tag: "Shadowsocks - Server Address") as! TextRow).value!
                    let shadowsocksServerPort = (self.form.rowBy(tag: "Shadowsocks - Server Port") as! IntRow).value!
                    let shadowsocksLocalAddress = (self.form.rowBy(tag: "Shadowsocks - Local Address") as! TextRow).value!
                    let shadowsocksLocalPort = (self.form.rowBy(tag: "Shadowsocks - Local Port") as! IntRow).value!
                    let shadowsocksPassword = (self.form.rowBy(tag: "Shadowsocks - Password") as! PasswordRow).value!
                    let shadowsocksMethod = (self.form.rowBy(tag: "Shadowsocks - Method") as! ActionSheetRow<String>).value!
                    
                    Alamofire.request(generalPACURL).responseString { response in
                        if response.response?.statusCode != 200 || response.value == nil {
                            let alertController = UIAlertController(
                                title: NSLocalizedString("Configuration Failed", comment: ""),
                                message: NSLocalizedString("Unable to download data from the PAC URL.", comment: ""),
                                preferredStyle: .alert
                            )
                            alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
                            configuringAlertController.dismiss(animated: true) {
                                self.present(alertController, animated: true)
                            }
                            return
                        }
                        print("\(String(describing: response.value))")
                        
                        NETunnelProviderManager.loadAllFromPreferences { providerManagers, _ in
                            
                            if let providerManagers = providerManagers, providerManagers.count > 0 {
                                providerManager = providerManagers[0]
                                if providerManagers.count > 1 {
                                    for providerManager in providerManagers[1...] {
                                        providerManager.removeFromPreferences()
                                    }
                                }
                            }
                            
                            let providerConfiguration = NETunnelProviderProtocol()
                            providerConfiguration.serverAddress = shadowsocksServerAddress
                            providerConfiguration.providerConfiguration = [
                                "general_hide_vpn_icon": generalHideVPNIcon,
                                "general_pac_url": generalPACURL.absoluteString,
                                "general_pac_content": response.value!,
                                "general_pac_max_age": TimeInterval(generalPACMaxAge),
                                "shadowsocks_server_address": shadowsocksServerAddress,
                                "shadowsocks_server_port": UInt16(shadowsocksServerPort),
                                "shadowsocks_local_address": shadowsocksLocalAddress,
                                "shadowsocks_local_port": UInt16(shadowsocksLocalPort),
                                "shadowsocks_password": shadowsocksPassword,
                                "shadowsocks_method": shadowsocksMethod,
                            ]
                            
                            providerManager.localizedDescription = NSLocalizedString("Ladder", comment: "")
                            providerManager.protocolConfiguration = providerConfiguration
                            providerManager.isEnabled = true
                            providerManager.saveToPreferences { error in
                                if error == nil {
                                    
                                    // 保存设置
                                    ServerProfileManager.instance.save()
                                    
                                    providerManager.loadFromPreferences { error in
                                        if error == nil {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                try? providerManager.connection.startVPNTunnel()
                                            }
                                        }
                                    }
                                }
                                configuringAlertController.dismiss(animated: true) {
                                    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
                                    if error != nil {
                                        alertController.title = NSLocalizedString("Configuration Failed", comment: "")
                                        alertController.message = NSLocalizedString("Please try again.", comment: "")
                                        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
                                    } else {
                                        alertController.title = NSLocalizedString("Configured!", comment: "")
                                        if let p = self.profile {
                                            let profileMgr = ServerProfileManager.instance
                                            profileMgr.setActiveProfiledId(p.uuid)
                                        }
                                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationKey.reloadServerDataNotif), object: nil)
                                    }
                                    self.present(alertController, animated: true) {
                                        if error == nil {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                alertController.dismiss(animated: true)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
    }
}

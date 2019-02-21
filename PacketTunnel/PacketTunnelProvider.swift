//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by Aofei Sheng on 2018/3/23.
//  Copyright © 2018 Aofei Sheng. All rights reserved.
//

import Alamofire
import NetworkExtension

class PacketTunnelProvider: NEPacketTunnelProvider {
	var shadowsocks: Shadowsocks?

	override func startTunnel(options _: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
		let providerConfiguration = (protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration!
		let generalHideVPNIcon = providerConfiguration["general_hide_vpn_icon"] as! Bool
		let generalPACURL = URL(string: providerConfiguration["general_pac_url"] as! String)!
		let generalPACContent = providerConfiguration["general_pac_content"] as! String
		let generalPACMaxAge = providerConfiguration["general_pac_max_age"] as! TimeInterval
		let shadowsocksServerAddress = lookupIPAddress(hostname: providerConfiguration["shadowsocks_server_address"] as! String)!
		let shadowsocksServerPort = providerConfiguration["shadowsocks_server_port"] as! UInt16
		let shadowsocksLocalAddress = lookupIPAddress(hostname: providerConfiguration["shadowsocks_local_address"] as! String)!
		let shadowsocksLocalPort = providerConfiguration["shadowsocks_local_port"] as! UInt16
		let shadowsocksPassword = providerConfiguration["shadowsocks_password"] as! String
		let shadowsocksMethod = providerConfiguration["shadowsocks_method"] as! String

		let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: shadowsocksServerAddress)
		networkSettings.dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4", "2001:4860:4860::8888", "2001:4860:4860::8844"])
		networkSettings.proxySettings = NEProxySettings()
		networkSettings.proxySettings?.autoProxyConfigurationEnabled = true
		if generalPACMaxAge == 0 {
			networkSettings.proxySettings?.proxyAutoConfigurationURL = generalPACURL
		} else {
			networkSettings.proxySettings?.proxyAutoConfigurationJavaScript = generalPACContent
		}
		networkSettings.proxySettings?.excludeSimpleHostnames = true
		networkSettings.proxySettings?.matchDomains = [""]
		networkSettings.ipv4Settings = NEIPv4Settings(addresses: generalHideVPNIcon ? [] : ["10.0.0.1"], subnetMasks: generalHideVPNIcon ? [] : ["255.0.0.0"])
		networkSettings.ipv6Settings = NEIPv6Settings(addresses: generalHideVPNIcon ? [] : ["::ffff:a00:1"], networkPrefixLengths: generalHideVPNIcon ? [] : [96])
		networkSettings.mtu = 1500

		setTunnelNetworkSettings(networkSettings) { error in
			if error == nil && self.shadowsocks == nil {
				do {
					self.shadowsocks = Shadowsocks(
						serverAddress: shadowsocksServerAddress,
						serverPort: shadowsocksServerPort,
						localAddress: shadowsocksLocalAddress,
						localPort: shadowsocksLocalPort,
						password: shadowsocksPassword,
						method: shadowsocksMethod
					)
					try self.shadowsocks?.start()
				} catch let error {
					completionHandler(error)
					return
				}

				if generalPACMaxAge > 0 {
					self.updatePACPeriodically()
				}
			}
			completionHandler(error)
		}
	}

	override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
		if reason != .none {
			shadowsocks?.stop()
		}
		completionHandler()
	}

	func updatePACPeriodically() {
		var providerConfiguration = (protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration!
		let generalPACURL = URL(string: providerConfiguration["general_pac_url"] as! String)!
		let generalPACContent = providerConfiguration["general_pac_content"] as! String
		let generalPACMaxAge = providerConfiguration["general_pac_max_age"] as! TimeInterval

		Alamofire.request(generalPACURL).responseString { response in
			if response.response?.statusCode == 200, let pacContent = response.value, pacContent != generalPACContent {
				providerConfiguration["general_pac_content"] = pacContent

				self.stopTunnel(with: .none) {
					DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
						self.startTunnel(options: nil) { _ in }
					}
				}
			}

			DispatchQueue.main.asyncAfter(deadline: .now() + generalPACMaxAge) {
				self.updatePACPeriodically()
			}
		}
	}

	func lookupIPAddress(hostname: String) -> String? {
		let host = CFHostCreateWithName(nil, hostname as CFString).takeRetainedValue()
		CFHostStartInfoResolution(host, .addresses, nil)
		for address in (CFHostGetAddressing(host, nil)?.takeUnretainedValue() as NSArray?) ?? [] {
			var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
			if let address = address as? NSData,
				getnameinfo(address.bytes.assumingMemoryBound(to: sockaddr.self), socklen_t(address.length), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
				return String(cString: hostname)
			}
		}
		return nil
	}
}

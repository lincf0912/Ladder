//
//  ServerProfile.swift
//  ShadowsocksX-NG
//
//  Created by 邱宇舟 on 16/6/6.
//  Copyright © 2016年 qiuyuzhou. All rights reserved.
//

#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(OSX)
import Cocoa
#else
//println("OMG, it's that mythical new Apple product!!!")
#endif



class ServerProfile: NSObject, NSCopying {
    
    @objc var uuid: String

    @objc var hideVPNIcon: Bool = false
    @objc var serverHost: String = ""
    @objc var serverPort: uint_fast16_t = 8379
    @objc var method:String = "aes-128-gcm"
    @objc var password:String = ""
    @objc var remark:String = ""
    
    override init() {
        uuid = UUID().uuidString
    }

    init(uuid: String) {
        self.uuid = uuid
    }

    convenience init?(url: URL) {
        self.init()

        func padBase64(string: String) -> String {
            var length = string.count
            if length % 4 == 0 {
                return string
            } else {
                length = 4 - length % 4 + length
                return string.padding(toLength: length, withPad: "=", startingAt: 0)
            }
        }

        func decodeUrl(url: URL) -> String? {
            let urlStr = url.absoluteString
            let index = urlStr.index(urlStr.startIndex, offsetBy: 5)
            let encodedStr = urlStr[index...]
            guard let data = Data(base64Encoded: padBase64(string: String(encodedStr))) else {
                return url.absoluteString
            }
            guard let decoded = String(data: data, encoding: String.Encoding.utf8) else {
                return nil
            }
            let s = decoded.trimmingCharacters(in: CharacterSet(charactersIn: "\n"))
            return "ss://\(s)"
        }

        guard let decodedUrl = decodeUrl(url: url) else {
            return nil
        }
        guard var parsedUrl = URLComponents(string: decodedUrl) else {
            return nil
        }
        guard let host = parsedUrl.host, let port = parsedUrl.port,
            let user = parsedUrl.user else {
            return nil
        }

        self.serverHost = host
        self.serverPort = uint_fast16_t(port)

        // This can be overriden by the fragment part of SIP002 URL
        remark = parsedUrl.queryItems?
            .filter({ $0.name == "Remark" }).first?.value ?? ""

        if let password = parsedUrl.password {
            self.method = user.lowercased()
            self.password = password
        } else {
            // SIP002 URL have no password section
            guard let data = Data(base64Encoded: padBase64(string: user)),
                let userInfo = String(data: data, encoding: .utf8) else {
                return nil
            }

            let parts = userInfo.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count != 2 {
                return nil
            }
            self.method = String(parts[0]).lowercased()
            self.password = String(parts[1])

            // SIP002 defines where to put the profile name
            if let profileName = parsedUrl.fragment {
                self.remark = profileName
            }
        }
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = ServerProfile()
        copy.hideVPNIcon = self.hideVPNIcon
        copy.serverHost = self.serverHost
        copy.serverPort = self.serverPort
        copy.method = self.method
        copy.password = self.password
        copy.remark = self.remark
        
        return copy;
    }
    
    static func fromDictionary(_ data:[String:Any?]) -> ServerProfile {
        let cp = {
            (profile: ServerProfile) in
            profile.hideVPNIcon = data["HideVPNIcon"] as! Bool
            profile.serverHost = data["ServerHost"] as! String
            profile.serverPort = (data["ServerPort"] as! NSNumber).uint16Value
            profile.method = data["Method"] as! String
            profile.password = data["Password"] as! String
            if let remark = data["Remark"] {
                profile.remark = remark as! String
            }
        }

        if let id = data["Id"] as? String {
            let profile = ServerProfile(uuid: id)
            cp(profile)
            return profile
        } else {
            let profile = ServerProfile()
            cp(profile)
            return profile
        }
    }

    func toDictionary() -> [String:AnyObject] {
        var d = [String:AnyObject]()
        d["Id"] = uuid as AnyObject?
        d["HideVPNIcon"] = hideVPNIcon as AnyObject?
        d["ServerHost"] = serverHost as AnyObject?
        d["ServerPort"] = NSNumber(value: serverPort as UInt16)
        d["Method"] = method as AnyObject?
        d["Password"] = password as AnyObject?
        d["Remark"] = remark as AnyObject?
        return d
    }

    func isValid() -> Bool {
        func validateIpAddress(_ ipToValidate: String) -> Bool {

            var sin = sockaddr_in()
            var sin6 = sockaddr_in6()

            if ipToValidate.withCString({ cstring in inet_pton(AF_INET6, cstring, &sin6.sin6_addr) }) == 1 {
                // IPv6 peer.
                return true
            }
            else if ipToValidate.withCString({ cstring in inet_pton(AF_INET, cstring, &sin.sin_addr) }) == 1 {
                // IPv4 peer.
                return true
            }

            return false;
        }

        func validateDomainName(_ value: String) -> Bool {
            let validHostnameRegex = "^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\\-]*[a-zA-Z0-9])\\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\\-]*[A-Za-z0-9])$"

            if (value.range(of: validHostnameRegex, options: .regularExpression) != nil) {
                return true
            } else {
                return false
            }
        }

        if !(validateIpAddress(serverHost) || validateDomainName(serverHost)){
            return false
        }

        if password.isEmpty {
            return false
        }

        return true
    }
    
    func title() -> String {
        if remark.isEmpty {
            return "\(serverHost):\(serverPort)"
        } else {
            return "\(remark) (\(serverHost):\(serverPort))"
        }
    }
    
}

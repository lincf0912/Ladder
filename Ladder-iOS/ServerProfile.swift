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
    
    @objc var PAC_URL: String = "https://git.io/fAPIe"
    @objc var PAC_Max_Age: uint_fast16_t = 3600
    
    @objc var localHost: String = "127.0.0.1"
    @objc var localPort: uint_fast16_t = 1081
    
    @objc var ssrProtocol:String = "origin"
    @objc var ssrProtocolParam:String = ""
    @objc var ssrObfs:String = "plain"
    @objc var ssrObfsParam:String = ""
    @objc var ssrGroup: String = ""
    
    override init() {
        uuid = UUID().uuidString
    }

    init(uuid: String) {
        self.uuid = uuid
    }

    convenience init?(url: URL) {
        self.init()

        if (url.host == nil) {
            return nil
        }
        
        let urlString = url.absoluteString
        if urlString.hasPrefix("ss://") {
            if (!parseSSURL(url: url)) {
                return nil
            }
        }
        if urlString.hasPrefix("ssr://") {
            if (!parseSSRURL(url: url)) {
                return nil
            }
        }
    }
    
    func parseSSURL(url:URL) -> Bool {
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
            return false
        }
        guard var parsedUrl = URLComponents(string: decodedUrl) else {
            return false
        }
        guard let host = parsedUrl.host, let port = parsedUrl.port,
            let user = parsedUrl.user else {
                return false
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
                    return false
            }
            
            let parts = userInfo.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            if parts.count != 2 {
                return false
            }
            self.method = String(parts[0]).lowercased()
            self.password = String(parts[1])
            
            // SIP002 defines where to put the profile name
            if let profileName = parsedUrl.fragment {
                self.remark = profileName
            }
        }
        return true
    }
    
    func parseSSRURL(url:URL) -> Bool {
        // ssr:// + base64(abc.xyz:12345:auth_sha1_v2:rc4-md5:tls1.2_ticket_auth:{base64(password)}/?obfsparam={base64(混淆参数(网址))}&protoparam={base64(混淆协议)}&remarks={base64(节点名称)}&group={base64(分组名)})
        
        func decode64(string: String) -> String? {
            
            var str = string.replacingOccurrences(of: "-", with: "+")
            str = str.replacingOccurrences(of: "_", with: "/")
            
            if str.count%4 > 0 {
                let length = (4-str.count%4)+str.count
                str = str.padding(toLength: length, withPad: "=", startingAt: 0)
            }
            
            guard let decodeData = Data(base64Encoded: str, options: .init(rawValue: 0)) else {
                return nil
            }
            guard let decodeStr = String(data: decodeData, encoding: String.Encoding.utf8) else {
                return nil
            }
            return decodeStr
        }
        
        func parseSSRLastParam(lastParam: String?) -> Dictionary<String, Any>? {
            
            guard let realParam = lastParam else {
                return nil;
            }
            
            var parserLastParamDict = Dictionary<String, Any>()
            
            let param = realParam.suffix(realParam.count-1)
            let lastParamArray = param.components(separatedBy: "&")
            
            for toSplitString in lastParamArray {
                guard let lastParamSplit = toSplitString.range(of: "=") else {continue}
                let key = String(toSplitString[..<lastParamSplit.lowerBound])
                let value = decode64(string: String(toSplitString[lastParamSplit.upperBound...]))
                parserLastParamDict[key] = value
            }
            return parserLastParamDict;
        }
    
        var firstParam:String
        var lastParam:String?
        var urlString = url.absoluteString

        urlString = urlString.replacingOccurrences(of: "ssr://", with: "", options: .anchored, range: urlString.startIndex ..<  urlString.endIndex)
        
        guard let decodedString = decode64(string: urlString) else {
            return false
        }
        print("decodedString:\(decodedString)")
        if let paramSplit = decodedString.range(of: "?") {
            let offsetIndex: String.Index = decodedString.index(paramSplit.lowerBound, offsetBy:-1)
            firstParam = String(decodedString[..<offsetIndex])
            lastParam = String(decodedString[paramSplit.lowerBound...])
        } else {
            firstParam = decodedString
        }
        
        let parserLastParamDict = parseSSRLastParam(lastParam: lastParam)
        
        //后面已经parser完成，接下来需要解析到profile里面
        //abc.xyz:12345:auth_sha1_v2:rc4-md5:tls1.2_ticket_auth:{base64(password)}
        let allParam = firstParam.components(separatedBy: ":")
        print("\(firstParam) \n \(allParam)")
        if allParam.count < 6 {return false}

        //第一个参数是域名
        let ip = allParam[0]
        self.serverHost = ip
        
        //第二个参数是端口
        let port = allParam[1]
        self.serverPort = uint_fast16_t(Int(port)!)
        
        //第三个参数是协议
        let ssrProtocol = allParam[2]
        self.ssrProtocol = ssrProtocol
        
        //第四个参数是加密
        let encryption = allParam[3]
        self.method = encryption
        
        //第五个参数是混淆协议
        let ssrObfs = allParam[4]
        self.ssrObfs = ssrObfs
        
        //第六个参数是base64密码
        let password = decode64(string: allParam[5])
        self.password = password ?? ""
        
        if let ssrObfsParam = parserLastParamDict?["obfsparam"] {
            self.ssrObfsParam = ssrObfsParam as! String
        }
        if let remarks = parserLastParamDict?["remarks"] {
            self.remark = remarks as! String
        }
        if let ssrProtocolParam = parserLastParamDict?["protoparam"] {
            self.ssrProtocolParam = ssrProtocolParam as! String
        }
        if let ssrGroup = parserLastParamDict?["group"] {
            self.ssrGroup = ssrGroup as! String
        }
        
        return true
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = ServerProfile()
        copy.hideVPNIcon = self.hideVPNIcon
        copy.serverHost = self.serverHost
        copy.serverPort = self.serverPort
        copy.method = self.method
        copy.password = self.password
        copy.remark = self.remark
        
        copy.PAC_URL = self.PAC_URL
        copy.PAC_Max_Age = self.PAC_Max_Age
        
        copy.localHost = self.localHost
        copy.localPort = self.localPort
        
        copy.ssrObfs = self.ssrObfs
        copy.ssrObfsParam = self.ssrObfsParam
        copy.ssrProtocol = self.ssrProtocol
        copy.ssrProtocolParam = self.ssrProtocolParam
        copy.ssrGroup = self.ssrGroup
        
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
            
            profile.PAC_URL = data["PAC_URL"] as! String
            profile.PAC_Max_Age = (data["PAC_Max_Age"] as! NSNumber).uint16Value
            
            profile.localHost = data["LocalHost"] as! String
            profile.localPort = (data["LocalPort"] as! NSNumber).uint16Value
            
            if let ssrObfs = data["ssrObfs"] {
                profile.ssrObfs = (ssrObfs as! String).lowercased()
            }
            if let ssrObfsParam = data["ssrObfsParam"] {
                profile.ssrObfsParam = ssrObfsParam as! String
            }
            if let ssrProtocol = data["ssrProtocol"] {
                profile.ssrProtocol = (ssrProtocol as! String).lowercased()
            }
            if let ssrProtocolParam = data["ssrProtocolParam"]{
                profile.ssrProtocolParam = ssrProtocolParam as! String
            }
            if let ssrGroup = data["ssrGroup"]{
                profile.ssrGroup = ssrGroup as! String
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
        
        d["PAC_URL"] = PAC_URL as AnyObject?
        d["PAC_Max_Age"] = NSNumber(value: PAC_Max_Age as UInt16)
        
        d["LocalHost"] = localHost as AnyObject?
        d["LocalPort"] = NSNumber(value: localPort as UInt16)
        
        d["ssrProtocol"] = ssrProtocol as AnyObject?
        d["ssrProtocolParam"] = ssrProtocolParam as AnyObject?
        d["ssrObfs"] = ssrObfs as AnyObject?
        if ssrObfs == "tls1.2_ticket_fastauth" {
            d["ssrObfs"] = "tls1.2_ticket_auth" as AnyObject?
        }
        d["ssrObfsParam"] = ssrObfsParam as AnyObject?
        d["ssrGroup"] = ssrGroup as AnyObject?
        
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
        
        if (ssrProtocol.isEmpty && !ssrObfs.isEmpty)||(!ssrProtocol.isEmpty && ssrObfs.isEmpty){
            return false
        }

        return true
    }
    
    func title() -> String {
        return "\(serverHost):\(serverPort)"
    }
    
}

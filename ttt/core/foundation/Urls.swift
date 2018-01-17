//
//  Urls.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/15.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

final class Urls {
    
    /// query value defined
    enum QValue {
        case value(String)
        case array([String])
        
        // value支持 String
        public init<S: StringProtocol>(_ string: S) {self = .value("\(string)")}
        
        // array支持
        public init<C: Sequence>(_ array: C) where C.Iterator.Element: StringProtocol {
            var ary = [] as [String]
            for value in array {
                ary.append("\(value)")
            }
            self = .array(ary)
        }
        public init<C: Sequence>(_ array: C) where C.Iterator.Element == Int {
            var ary = [] as [String]
            for value in array {
                ary.append("\(value)")
            }
            self = .array(ary)
        }

        
        // support int
        public init(_ int: Int) {self = .value("\(int)")}
        public init(_ int8: Int8) {self = .value("\(int8)")}
        public init(_ int16: Int16) {self = .value("\(int16)")}
        public init(_ int32: Int32) {self = .value("\(int32)")}
        public init(_ int64: Int64) {self = .value("\(int64)")}
        
        public init(_ uint: UInt) {self = .value("\(uint)")}
        public init(_ uint8: UInt8) {self = .value("\(uint8)")}
        public init(_ uint16: UInt16) {self = .value("\(uint16)")}
        public init(_ uint32: UInt32) {self = .value("\(uint32)")}
        public init(_ uint64: UInt64) {self = .value("\(uint64)")}
        
        //Float
        public init(_ float: Float) {self = .value("\(float)")}
        
        // Double
        public init(_ double: Double) {self = .value("\(double)")}
        
        // Bool
        public init(_ bool: Bool) {self = .value("\(bool)")}
        
        // Character
        public init(_ char: Character) {self = .value("\(char)")}
        
        // get string
        public var string: String? { get{ switch self { case QValue.value(let value): return value; default: break }; return nil } }
        
        // get [string]
        public var array: [String]? { get{ switch self { case QValue.array(let array): return array; default: break }; return nil } }
        
        // get bool
        public var bool: Bool? {
            get{
                switch self {
                case QValue.value(let value):
                    let v = value.lowercased()
                    if v == "true" || v == "yes" || v == "on" || v == "1" || v == "t" || v == "y" {
                        return true
                    } else if v == "false" || v == "no" || v == "off" || v == "0" || v == "f" || v == "n" {
                        return false
                    }
                    break
                default: break
                }
                return nil
            }
        }
        
        // get char
        public var char: Character? {
            get{
                switch self {
                case QValue.value(let value):
                    if value.count == 1 {
                        return value[value.startIndex]
                    }
                    break
                default: break
                }
                return nil
            }
        }
        
        // get double
        public var double: Double? { get{ switch self { case QValue.value(let value): return Double(value); default: break }; return nil } }
        
        // get float
        public var float: Float? { get{ switch self { case QValue.value(let value): return Float(value); default: break }; return nil } }
        
        // get int
        public var int: Int? { get{ switch self { case QValue.value(let value): return Int(value); default: break }; return nil } }
        public var int8: Int8? { get{ switch self { case QValue.value(let value): return Int8(value); default: break }; return nil } }
        public var int16: Int16? { get{ switch self { case QValue.value(let value): return Int16(value); default: break }; return nil } }
        public var int32: Int32? { get{ switch self { case QValue.value(let value): return Int32(value); default: break }; return nil } }
        public var int64: Int64? { get{ switch self { case QValue.value(let value): return Int64(value); default: break }; return nil } }
        public var uint: UInt? { get{ switch self { case QValue.value(let value): return UInt(value); default: break }; return nil } }
        public var uint8: UInt8? { get{ switch self { case QValue.value(let value): return UInt8(value); default: break }; return nil } }
        public var uint16: UInt16? { get{ switch self { case QValue.value(let value): return UInt16(value); default: break }; return nil } }
        public var uint32: UInt32? { get{ switch self { case QValue.value(let value): return UInt32(value); default: break }; return nil } }
        public var uint64: UInt64? { get{ switch self { case QValue.value(let value): return UInt64(value); default: break }; return nil } }
        
        
        // json obj support
        public init<C: MMJsonable>(_ entity: C) {self = .value("\(entity.ssn_jsonString())")}
        public func json<C: MMJsonable>(_ type: C.Type) -> C? {
            switch self {
            case QValue.value(let value):
                return type.ssn_from(json: value)
            default: break
            }
            return nil
        }
    }
    
    
    /// query url encode
    public static func encoded(str:String) -> String {
        let value = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if value == nil {
            return str
        }
        return value!
    }
    
    /// query url decode
    public static func decoded(str:String) -> String {
        let value = str.removingPercentEncoding
        if value == nil {
            return str
        }
        return value!
    }
    
    /// get url query dictionary
    public static func query(url: String, decord: Bool = true) ->Dictionary<String,QValue> {
        let surl = encoding(url: url)
        guard let q = URL(string:surl) else {return Dictionary<String,QValue>()}
        return query(query:q.query!, decord:decord)
    }
    
    /// get url fragment dictionary
    public static func fragment(url: String, decord: Bool = true) ->Dictionary<String,QValue> {
        let surl = encoding(url: url)
        guard let q = URL(string:surl) else {return Dictionary<String,QValue>()}
        return query(query:q.fragment!, decord:decord)
    }
    
    /// get query dictionary
    public static func query(query: String, decord: Bool = true) ->Dictionary<String,QValue> {
        var map = Dictionary<String,QValue>();
        let strs = query.trimmingCharacters(in: CharacterSet(charactersIn: "?#!")).split(separator: "&")
        for str in strs {
            let ss = str.split(separator: "=")
            var key = ""
            var value = ""
            if ss.count == 2 {
                key = String(ss[0])
                value = String(ss[1])
            } else if (ss.count == 1) {
                key = String(ss[0])
            } else if (ss.count > 2) {
                let range = str.range(of:"=")
                key = String(str[str.startIndex...range!.lowerBound])
                value = String(str[range!.upperBound..<str.endIndex])
            }
            if !key.isEmpty {
                
                if decord && !value.isEmpty {
                    value = decoded(str: value)
                }
                
                let v = map[key]
                if v != nil {
                    switch v! {
                        case QValue.value(let vv):
                            var list = [vv,value]
                            list.sort()
                            map[key] = QValue.array(list)
                            break
                        case QValue.array(var list):
                            list.append(value)
                            list.sort()
                            map[key] = QValue.array(list)
                            break
                    }
                } else {
                    map[key] = QValue.value(value)
                }
            }
        }
        return map
    }
    
    /// get query string
    public static func queryString(dic: Dictionary<String,QValue>, encode: Bool = true) ->String {
        var result = ""
        let keys = dic.keys.sorted()
        for key in keys {
            let qvalue = dic[key]
            
            switch qvalue! {
            case QValue.value(let value):
                if !result.isEmpty {
                    result += "&"
                }
                if encode {
                    result += key + "=" + self.encoded(str: value)
                } else {
                    result += key + "=" + value
                }
                break
            case QValue.array(let array):
                let list = array.sorted()
                for str in list {
                    if !result.isEmpty {
                        result += "&"
                    }
                    if encode {
                        result += key + "=" + self.encoded(str: str)
                    } else {
                        result += key + "=" + str
                    }
                }
                break
            }
        }
        
        return result
    }
    
//    private static let URL_ALLOWED_CHARS = CharacterSet.init(charactersIn: "!*'();:@&=+$,/?%#[]")
    
    /// Save the final form of the url.
    private static let URL_ALLOWED_CHARS = CharacterSet.init(charactersIn: "$'()*+,[]@ ").inverted //!?#& RFC 3986
    
    
    public static func encoding(url:String) -> String {
        var surl = url.removingPercentEncoding
        if surl != nil {
            surl = surl!.addingPercentEncoding(withAllowedCharacters: URL_ALLOWED_CHARS)
        } else {
            surl = url
        }
        return surl!
    }
    
    /// tidy <scheme>://<host>:<port>/<path>;<params>?<query>#<fragment> , case sensitive path
    /// just uri:<scheme>://<host>:<port>/<path>;<params>
    /// *param: only is just url path
    /// *param: sensitve is path case sensitve
    public static func tidy(url:String, path only:Bool = false, case sensitve:Bool = false) -> String {
        //decoding and encoding can compatibility more scene
        let surl = encoding(url: url)
        
        let uri = URL(string:surl)
        if (uri == nil) {return url}
        var result = ""
        
        // scheme
        let scheme = uri?.scheme
        if scheme != nil {
            result = scheme!.lowercased() + "://"
        } else {//default https
            result = "https://"
        }
        
        //user and password
        let user = uri?.user
        let pswd = uri?.password
        if user != nil && pswd != nil {
            result += user! + ":" + pswd! + "@"
        } else if user != nil {
            result += user! + "@"
        }
        
        // host
        let host = uri?.host
        if host != nil {
            result += host!.lowercased()
        } else {//default https
            result += "m.mymm.com"
        }
        
        // port
        let port = uri?.port
        if port != nil {
            if scheme!.lowercased() == "http" && port! == 80 {
                // normal
            } else if scheme!.lowercased() == "https" && port! == 443 {
                // normal
            } else {
                result += ":\(port!)"
            }
        }
        
        // path
        let paths = uri?.pathComponents
        if paths != nil {
            for path in paths! {
                if (path.isEmpty || path == "/" || path == "." || path == "..") {
                    continue
                }
                if sensitve {
                    result += "/" + path
                } else {
                    result += "/" + path.lowercased()
                }
            }
        }
        
        if only {
            return result
        }
        
        //query
        let query = uri?.query
        if query != nil {
            let dic = self.query(query: query!)
            let str = self.queryString(dic: dic)
            if !str.isEmpty {
                result += "?" + str
            }
        }
        
        //fragment
        let fragment = uri?.fragment
        if fragment != nil {
            let dic = self.query(query: fragment!)
            if dic.isEmpty {//just string 
                result += "#" + fragment!
            } else {
                let str = self.queryString(dic: dic)
                if !str.isEmpty {
                    result += "#" + str
                }
            }
        }
        
        return result
    }
    
    /// compared <scheme>://<host>:<port>/<path>;<params>?<query>#<fragment>
    public static func isEqualURL(_ url:String, _ turl:String, case sensitve:Bool = false) -> Bool {
        let url1 = self.tidy(url: url, path: false, case: sensitve)
        let url2 = self.tidy(url: turl, path: false, case: sensitve)
        return url1 == url2
    }
    
    /// compared <scheme>://<host>:<port>/<path>;<params>
    public static func isEqualURLPath(_ url:String, _ turl:String, case sensitve:Bool = false) -> Bool {
        let url1 = self.tidy(url: url, path: true, case: sensitve)
        let url2 = self.tidy(url: turl, path: true, case: sensitve)
        return url1 == url2
    }
    
    /**
     * 获取url中除去host之后的path, 如果遇到 http://m.mymm.com/detail/{skuid}.html 类型，则匹配保留 detail/{_}.html
     * @param url
     * @return
     */
    public static func getURLFinderPath(url: String) -> String  {
        let surl = encoding(url: url)
        let uri = URL(string:surl)
        
        if (uri == nil) {return ""}
        
        let host = uri!.host
        if (host == nil || host!.isEmpty) {
            return "";
        }
        
        let paths = uri!.pathComponents
        if (paths.isEmpty) {//home page: https://m.mymm.com
            return "/";
        }
        
        var builder = String();
        var isFirst = true;
        for p in paths {
            if (!p.isEmpty && p != "/" && p != "." && p != "..") {
                var str = p;
                //contain param key
                if p.contains("{") && p.contains("}") {
                    let range = p.range(of: "}")!.upperBound ..< str.endIndex
                    str = "{_}" + p[range];
                }
                
                if (isFirst) {
                    isFirst = false;
                }
                else {
                    builder.append("/");
                }
                
                // 不区分大小写，不一定合理，兼容方案; Not case sensitive.
                builder.append(str.lowercased());
            }
        }
        
        if builder.isEmpty {
            return "/"
        }
        
        return builder;
    }
    
    // just support last component param key
    public static func getURLPathParamKey(url: String) -> String  {
        let surl = encoding(url: url)
        let uri = URL(string:surl)
        
        if (uri == nil) {return ""}
        
        let host = uri!.host
        if (host == nil || host!.isEmpty) {
            return ""
        }
        
        let paths = uri!.pathComponents
        if (paths.isEmpty) {//home page: https://m.mymm.com
            return ""
        }
        
        for path in paths {
            if (path.isEmpty || path == "/" || path == "." || path == "..") {
                continue
            }
            
            if path.contains("{") && path.contains("}") {
                return "";
            }
            
            let range = path.range(of: "{")!.upperBound ..< path.range(of: "}")!.lowerBound
            return String(path[range])
        }
        
        return ""
    }
}

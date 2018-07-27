//
//  Urls.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/15.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation


public struct QBundle :Collection {
    
    public typealias Index = Dictionary<String,QValue>.Index
    public var startIndex:Index{ get{ return _map.startIndex } }
    public var endIndex:Index{ get{ return _map.endIndex } }
    public typealias Element = Dictionary<String,QValue>.Element
    
    public subscript (_ i:QBundle.Index) -> Element { get{ return _map[i] } }
    public func index(after i: QBundle.Index) -> QBundle.Index {
        return _map.index(after:i)
    }
    
    var _map:Dictionary<String,QValue>!
    public init() {
        _map = Dictionary<String,QValue>()
    }
    public init(dictionary:[String:QValue]) {
        _map = Dictionary<String,QValue>()
        for (key,value) in dictionary {
            _map[key] = value
        }
    }
    public init(minimumCapacity: Int) {
        _map = Dictionary(minimumCapacity: minimumCapacity)
    }
    public init<S>(uniqueKeysWithValues keysAndValues: S) where S : Sequence, S.Element == (String,QValue) {
        _map = Dictionary(uniqueKeysWithValues: keysAndValues)
    }
    public init<S>(_ keysAndValues: S, uniquingKeysWith combine: (QValue, QValue) throws -> QValue) rethrows where S : Sequence, S.Element == (String,QValue) {
        _map = try Dictionary(keysAndValues, uniquingKeysWith:combine)
    }
    
    public subscript(key: String) -> QValue? {
        get {
            if let v = _map[key] {
                return v
            } else if let v = _map[key.lowercased()] {
                return v
            }
            return nil
        }
        set {
            _map[key] = newValue
        }
    }
    

    public var isEmpty: Bool { get{ return _map.isEmpty } }
    
    public var first: (key: String, value: QValue)? { get{ return _map.first } }
    
    public var count: Int { get{ return _map.count } }
    
    public var keys: Dictionary<String, QValue>.Keys { get{ return _map.keys } }

    public var values: Dictionary<String, QValue>.Values { get{ return _map.values } }
    
    public mutating func merge(_ other: [String : QValue], uniquingKeysWith combine: (QValue, QValue) throws -> QValue) rethrows {
        try _map.merge(other, uniquingKeysWith: combine)
    }
    
    
    public func merging(_ other: [String : QValue], uniquingKeysWith combine: (QValue, QValue) throws -> QValue) rethrows -> QBundle {
        let rt = try _map.merging(other, uniquingKeysWith: combine)
        return QBundle(dictionary:rt)
    }
    
    public mutating func remove(at index: QBundle.Index) -> QBundle.Element {
        return _map.remove(at: index)
    }
    
    public mutating func removeValue(forKey key: String) -> QValue? {
        return _map.removeValue(forKey: key)
    }
    
    public mutating func removeAll(keepingCapacity keepCapacity: Bool = true) {
        _map.removeAll(keepingCapacity:keepCapacity)
    }
    
    public static func convert(dic:Dictionary<String,AnyObject>) -> QBundle {
        var query = QBundle()
        for (key,value) in dic {
            if Injects.isBaseType(value) {
                query[key] = QValue("\(value)")
            } else if let entity = value as? MMJsonable {
                query[key] = QValue("\(entity.ssn_jsonString())")
            } else if let v = value as? QValue {
                query[key] = v
            }
        }
        return query
    }
    
    public static func convert(query:QBundle) -> Dictionary<String,AnyObject> {
        var dic = Dictionary<String,AnyObject>()
        for (key,value) in query {
            switch value {
            case QValue.value(let v):
                dic[key] = v as AnyObject
                break
            case QValue.array(let l):
                dic[key] = l as AnyObject
                break
            }
        }
        return dic
    }
}

/// query value defined
public enum QValue {
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

extension URL {
    public var encodedPathComponents: [String] {
        get {
            var eps = [] as [String]
            let ps = self.pathComponents
            for str in ps {
                if let en = str.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
                    eps.append(en)
                } else {
                    eps.append(str)
                }
            }
            
            return eps
        }
    }
    
    public var encodedFragmentPathComponents: [String] {
        get {
            
            var eps = [] as [String]
            if let fgmt = self.fragment,fgmt.hasPrefix("/") && fgmt.count > 1 {
                
                //单页应用存在非标准的query参数 如：#/product/3918744?from=singlemessage
                let ss = fgmt.split(separator: "?")
                let fp = ss.count > 1 ? String(ss[0]) : fgmt
                
                let fs = fp.split(separator: "/")
                for sub in fs {
                    if let en = String(sub).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {
                        eps.append(en)
                    } else {
                        eps.append(String(sub))
                    }
                }
            }
            
            return eps
         }
    }
}

public final class Urls {
    
    /// query url encode
    public static func encoded(str:String) -> String {
        guard let value = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return str
        }
        return value
    }
    
    /// query url decode
    public static func decoded(str:String) -> String {
        guard let value = str.removingPercentEncoding else {
            return str
        }
        return value
    }
    
    /// get url query dictionary
    public static func query(url: URL, decord: Bool = true) -> QBundle {
        guard let q = url.query else {return QBundle()}
        return query(query:q, decord:decord)
    }
    
    public static func query(url: String, decord: Bool = true) -> QBundle {
        let surl = encoding(url: url)
        guard let u = URL(string:surl) else {return QBundle()}
        guard let q = u.query else {return QBundle()}
        return query(query:q, decord:decord)
    }
    
    /// get url fragment dictionary
    public static func fragment(url: String, decord: Bool = true) -> QBundle {
        let surl = encoding(url: url)
        guard let u = URL(string:surl) else {return QBundle()}
        guard let f = u.fragment else {return QBundle()}
        return query(query:f, decord:decord)
    }
    
    /// get url fragment dictionary
    public static func fragmentString(url: String, decord: Bool = true) -> String {
        let surl = encoding(url: url)
        guard let u = URL(string:surl) else { return "" }
        guard let f = u.fragment else { return "" }
        return f
    }
    
    /// get query dictionary
    public static func query(query: String, decord: Bool = true) -> QBundle {
        var map = QBundle();
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
                if let range = str.range(of:"=") {
                    key = String(str[str.startIndex...range.lowerBound])
                    value = String(str[range.upperBound..<str.endIndex])
                }
            }
            if !key.isEmpty {
                
                if decord && !value.isEmpty {
                    value = decoded(str: value)
                }
                
                if let v = map[key] {
                    switch v {
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
    public static func queryString(dic: QBundle, encode: Bool = true) ->String {
        var result = ""
        let keys = dic.keys.sorted()
        let valuse = dic.values
        if valuse.count == 1 {
            if let str = valuse.first?.string, str.isEmpty {
                return keys[0]
            }
        }
        for key in keys {
            if let qvalue = dic[key] {
                switch qvalue {
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
        }
        
        return result
    }
    
//    private static let URL_ALLOWED_CHARS = CharacterSet.init(charactersIn: "!*'();:@&=+$,/?%#[]")
    
    /// Save the final form of the url.
    private static let URL_ALLOWED_CHARS = CharacterSet.init(charactersIn: "$'()*+,[]@ ").inverted //!?#& RFC 3986
    
    
    public static func encoding(url:String) -> String {
        if let u = URL(string: url) {
            return u.absoluteString
        }
        guard let surl = url.removingPercentEncoding else { return url }
        guard let tsurl = surl.addingPercentEncoding(withAllowedCharacters: URL_ALLOWED_CHARS) else { return url }
        return tsurl
    }
    
    public static func append(url:String, key:String, value:QValue) -> String {
        return Urls.appends(url: url, dic: [key:value])
    }
    
    public static func appends(url:String, dic: Dictionary<String,QValue>) -> String {
        if dic.isEmpty {
            return url
        }
        var q = Urls.query(url: url, decord: true)
        for (key, value) in dic {
            q[key] = value
        }
        return Urls.tidy(url: url,query: q)
    }
    
    public static func appends(url:String, querys: QBundle) -> String {
        if querys.isEmpty {
            return url
        }
        var q = Urls.query(url: url, decord: true)
        for (key, value) in querys {
            q[key] = value
        }
        return Urls.tidy(url: url,query: q)
    }
    
    public static func scheme(url:String) -> String {
        //decoding and encoding can compatibility more scene
        let surl = encoding(url: url)
        
        guard let uri = URL(string:surl) else { return "" }
        
        if let scheme = uri.scheme {
            return scheme.lowercased()
        }
        
        return ""
    }
    
    public static func host(url:String) -> String {
        //decoding and encoding can compatibility more scene
        let surl = encoding(url: url)
        
        guard let uri = URL(string:surl) else { return "" }
        
        if let host = uri.host {
            return host.lowercased()
        }
        
        return ""
    }
    
    // 取当前url的地址,即：scheme://host
    public static func location(url:String) -> String {
        //decoding and encoding can compatibility more scene
        let surl = encoding(url: url)
        
        guard let uri = URL(string:surl) else { return "" }
        
        guard let host = uri.host else { return "" }
        
        if let scheme = uri.scheme {
            return scheme.lowercased() + "://" + host.lowercased()
        } else {
            return "http://" + host.lowercased()
        }
    }
    
    /// tidy <scheme>://<host>:<port>/<path>;<params>?<query>#<fragment> , case sensitive path
    /// just uri:<scheme>://<host>:<port>/<path>;<params>
    /// *param: only is just url path
    /// *param: sensitve is path case sensitve
    public static func tidy(url:String, path only:Bool = false, nofragment: Bool = false, case sensitve:Bool = true, scheme:String? = nil, host:String? = nil, query: QBundle? = nil, fragment: QBundle? = nil) -> String {
        //decoding and encoding can compatibility more scene
        let surl = encoding(url: url)
        
        guard let uri = URL(string:surl) else { return url }

        var result = ""
        
        // scheme
        var theSchm = ""
        if let schm = scheme, !schm.isEmpty {
            theSchm = schm.lowercased()
        } else if let schm = uri.scheme, !schm.isEmpty {
            theSchm = schm.lowercased()
        } else {//default https
            theSchm = "https"
        }
        result = theSchm + "://"
        
        //user and password
        if let user = uri.user, let pswd = uri.password {
            result += user + ":" + pswd + "@"
        } else if let user = uri.user {
            result += user + "@"
        }
        
        // host
        if let hst = host, !hst.isEmpty {
            result += hst.lowercased()
        } else if let hst = uri.host, !hst.isEmpty {
            result += hst.lowercased()
        } else {//default https
            result += "m.mymm.com"
        }
        
        // port
        if let port = uri.port {
            if port == 80 && theSchm.lowercased() == "http" {
                // normal
            } else if port == 443 && theSchm.lowercased() == "https"  {
                // normal
            } else {
                result += ":\(port)"
            }
        }
        
        // path
        let paths = uri.encodedPathComponents
        for path in paths {
            if (path.isEmpty || path == "/" || path == "." || path == "..") {
                continue
            }
            if sensitve {
                result += "/" + path
            } else {
                result += "/" + path.lowercased()
            }
        }
        
        if only {
            return result
        }
        
        //query
        var qry:QBundle = QBundle()
        if let query = query {
            qry = query
        } else if let strqry = uri.query {
            qry = self.query(query: strqry)
        }
        let str = self.queryString(dic: qry)
        if !str.isEmpty {
            result += "?" + str
        }
        
        if nofragment {
            return result
        }
        
        //fragment
        var frg:QBundle = QBundle()
        if let fragment = fragment {
            frg = fragment
        } else if let strqry = uri.fragment {
            frg = self.query(query: strqry)
        }
        let fstr = self.queryString(dic: frg)
        if !fstr.isEmpty {
            result += "#" + fstr
        }
//        if let fragment = uri.fragment {
//            let dic = self.query(query: fragment)
//            if dic.isEmpty {//just string
//                result += "#" + fragment
//            } else {
//                let str = self.queryString(dic: dic)
//                if !str.isEmpty {
//                    result += "#" + str
//                }
//            }
//        }
        
        return result
    }
    
    public static func appendFragmentPath(url:String, relativePath:String) -> String {
        var fragment = Urls.fragmentString(url: url)
        var params = ""
        if let idx = fragment.index(of: "?") {
            params = "\(fragment[idx..<fragment.endIndex])";
            fragment = "\(fragment[fragment.startIndex..<idx])";
        }
        
        //之前的fragment不含path结构，统一做参数
        if !fragment.isEmpty  && !fragment.starts(with: "/") {
            if (!params.isEmpty) {//多个 ? 不管了
                params = fragment + params;
            } else {
                params = "?" + fragment;
            }
            fragment = "";
        }
        
        var pathFragment = "";
        if relativePath.starts(with: "/") {
            pathFragment = fragment + relativePath + params;
        } else {
            pathFragment = fragment + "/" + relativePath + params;
        }
        
        var bundle = QBundle()
        bundle[pathFragment] = QValue("")
        return tidy(url: url, fragment: bundle)
    }
    
    /// compared <scheme>://<host>:<port>/<path>;<params>?<query>#<fragment>
    public static func isEqualURL(_ url:String, _ turl:String, case sensitve:Bool = false, scheme ignore1:Bool = false,host ignore2:Bool = false) -> Bool {
        var scheme:String? = nil
        var host:String? = nil
        if ignore1 {
            scheme = "https"
        }
        if ignore2 {
            host = "m.mymm.com"
        }
        
        let url1 = self.tidy(url: url, case: sensitve, scheme:scheme, host:host)
        let url2 = self.tidy(url: turl, case: sensitve, scheme:scheme, host:host)
        return url1 == url2
    }
    
    /// compared <scheme>://<host>:<port>/<path>;<params>?<query>
    public static func isEqualURI(_ url:String, _ turl:String, case sensitve:Bool = false, scheme ignore1:Bool = false,host ignore2:Bool = false) -> Bool {
        var scheme:String? = nil
        var host:String? = nil
        if ignore1 {
            scheme = "https"
        }
        if ignore2 {
            host = "m.mymm.com"
        }
        let url1 = self.tidy(url: url, nofragment: true,  case: sensitve, scheme:scheme, host:host)
        let url2 = self.tidy(url: turl, nofragment: true, case: sensitve, scheme:scheme, host:host)
        return url1 == url2
    }
    
    /// compared <scheme>://<host>:<port>/<path>;<params>
    public static func isEqualURLPath(_ url:String, _ turl:String, case sensitve:Bool = false, scheme ignore1:Bool = false,host ignore2:Bool = false) -> Bool {
        var scheme:String? = nil
        var host:String? = nil
        if ignore1 {
            scheme = "https"
        }
        if ignore2 {
            host = "m.mymm.com"
        }
        let url1 = self.tidy(url: url, path: true, case: sensitve, scheme:scheme, host:host)
        let url2 = self.tidy(url: turl, path: true, case: sensitve, scheme:scheme, host:host)
        return url1 == url2
    }
    
    /**
     * 获取url中除去host之后的path, 如果遇到 http://m.mymm.com/detail/{skuid}.html 类型，则匹配保留 detail/{_}.html
     * web单页应用支持 http://m.mymm.com#/product/{skuId}
     * @param url
     * @return
     */
    public static func getURLFinderPath(url: String, config:Bool = false) -> String  {
        let surl = encoding(url: url)
        var u = surl
        if config {
            u = surl.replacingOccurrences(of: "{", with: "-")//替换成允许的字符
            u = u.replacingOccurrences(of: "}", with: "_")//替换成允许的字符
        }
        
        guard let uri = URL(string:u) else { return "" }
        guard let host = uri.host else {
            return ""
        }
        if host.isEmpty {
            return ""
        }
        
        
        // 支持单页应用 #/product/{skuId}
        let fpaths = uri.encodedFragmentPathComponents
        
        // 实际的path
        let paths = uri.encodedPathComponents //非encode，需要处理
        if (paths.isEmpty && fpaths.isEmpty) {//home page: https://m.mymm.com
            return "/"
        }
        
        var builder = buildPath(paths: paths)
        
        // 单页应用支持
        if !fpaths.isEmpty {
            builder.append("#/")
        }
        
        builder.append(buildPath(paths: fpaths))
        
        if builder.isEmpty {
            return "/"
        }
        
        return builder
    }
    
    private static func buildPath(paths:[Any],case sensitve:Bool = true) -> String {
        var builder = String()
        var isFirst = true;
        for s in paths {
            var p = ""
            if let x = s as? String {
                p = x
            } else if let x = s as? Substring {
                p = String(x)
            }
            
            if (p.isEmpty || p == "/" || p == "." || p == "..") {
                continue
            }
            
            var str = p
            if p.hasPrefix("-") && p.contains("_") {
                if let range = p.range(of: "_",options: .backwards) {
                    str = "{_}" + p[range.upperBound..<p.endIndex]
                }
            }
            
            if (isFirst) {
                isFirst = false;
            }
            else {
                builder.append("/");
            }
            
            // 不区分大小写，不一定合理，兼容方案; Not case sensitive.
            if sensitve {
                builder.append(str)
            } else {
                builder.append(str.lowercased())
            }
        }
        return builder
    }
    
    private static func getPathKey(paths:[Any]) -> [String] {
        var keys:[String] = []
        var isLast = true
        for s in paths.reversed() {
            var path = ""
            if let x = s as? String {
                path = x
            } else if let x = s as? Substring {
                path = String(x)
            }
            
            if (path.isEmpty || path == "/" || path == "." || path == "..") {
                continue
            }
            
            //去掉末尾的.html
            if isLast {
                isLast = false
                if let range = path.range(of: ".", options: .backwards) {
                    path = String(path[path.startIndex..<range.lowerBound]);
                }
            }
            
            if !path.hasPrefix("-") || !path.hasSuffix("_") {
                continue;
            }
            
            let begin = path.index(path.startIndex, offsetBy: 1)
            let end = path.index(path.endIndex, offsetBy: -1)
            let range = begin ..< end
            keys.insert(String(path[range]), at: 0) //插入到前面
        }
        
        return keys
    }
    
    // just support last component param key
    public static func getURLPathParamKey(url: String) -> [String]  {
        var surl = encoding(url: url)
        surl = surl.replacingOccurrences(of: "{", with: "-")
        surl = surl.replacingOccurrences(of: "}", with: "_")
        guard let uri = URL(string:surl) else { return [] }
        guard let host = uri.host else {
            return []
        }
        if host.isEmpty {
            return []
        }
        
        // 支持单页应用 #/product/{skuId}
        let fpaths = uri.encodedFragmentPathComponents
        
        // 实际的path
        let paths = uri.encodedPathComponents
        if (paths.isEmpty && fpaths.isEmpty) {//home page: https://m.mymm.com
            return []
        }
        
        // 从fragment中获取
        var keys = getPathKey(paths: fpaths)
        
        //从后往前找
        let ks = getPathKey(paths: paths)
        if !ks.isEmpty {
            keys.insert(contentsOf: ks, at: 0)
        }
        
        return keys
    }
    
    //是否为合法的itunes地址
    public static func isItunesUrl(url:String, appId:inout String) -> Bool {
        //**前缀**+itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=**AppId**
        //**前缀**+itunes.apple.com/us/app/apple-store/id+**AppId**
        //**前缀**+itunes.apple.com/us/app/id+**AppId**?mt=8
        //**前缀**+itunes.apple.com/us/app/***sha-long-zhang-pai***/id1066602104?l=zh&ls=1&mt=8 (这个不常用，注 : 中间斜线文本是应用名拼音)
        //**前缀**+itunes.apple.com/app/id+**AppId**
       
        guard let uri = URL(string:Urls.encoding(url: url)) else { return false }
        
        guard let host = uri.host?.lowercased() else { return false }
        if host != "itunes.apple.com" {
            return false
        }
        
        guard let scheme = uri.scheme?.lowercased() else { return false }
        if scheme != "http" && scheme != "https" && scheme != "itms-apps" {
            return false
        }
        
        let path = uri.path
        var result = false
        if path == "/WebObjects/MZStore.woa/wa/viewSoftware" {
            if let str = uri.query, let id = Urls.query(query: str)["id"]?.string {
                appId = id
            }
            return true
        } else if path.starts(with: "/us/app/apple-store/id") {
            result = true
        } else if path.starts(with: "/us/app/id") {
            result = true
        }  else if path.starts(with: "/us/app/") {//不常见的方式，同样支持
            result = true
        } else if path.starts(with: "/app/id") {
            result = true
        }
        
        if result {
            let lpath = uri.lastPathComponent
            if lpath.count > 2 {
                let begin = lpath.index(lpath.startIndex, offsetBy: 2)
                let end = lpath.endIndex
                appId = String(lpath[begin..<end])
            }
        }
        return result
    }
}

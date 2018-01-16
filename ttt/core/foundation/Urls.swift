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
    }
    
    
    /**
     * 获取url中除去host之后的path, 如果遇到 http://m.mymm.com/detail/{skuid}.html 类型，则匹配保留 detail/{_}.html
     * @param url
     * @return
     */
    public static func getURLFinderPath(url: String) -> String  {
        let surl = compatibilityTidy(url: url)
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
        let surl = compatibilityTidy(url: url)
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
    
    /// query url encode
    public static func encode(str:String) -> String {
        let value = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if value == nil {
            return str
        }
        return value!
    }
    
    /// query url decode
    public static func decode(str:String) -> String {
        let value = str.removingPercentEncoding
        if value == nil {
            return str
        }
        return value!
    }
    
    /// get url query dictionary
    public static func query(url: String, decord: Bool = true) ->Dictionary<String,QValue> {
        let surl = compatibilityTidy(url: url)
        guard let q = URL(string:surl) else {return Dictionary<String,QValue>()}
        return query(query:q.query!, decord:decord)
    }
    
    /// get url fragment dictionary
    public static func fragment(url: String, decord: Bool = true) ->Dictionary<String,QValue> {
        let surl = compatibilityTidy(url: url)
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
                    value = decode(str: value)
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
                    result += key + "=" + self.encode(str: value)
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
                        result += key + "=" + self.encode(str: str)
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
    
    
    private static func compatibilityTidy(url:String) -> String {
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
    /// param: only is just url path
    /// param: sensitve is path case sensitve
    public static func tidy(url:String, path only:Bool = false, case sensitve:Bool = false) -> String {
        //decoding and encoding can compatibility more scene
        let surl = compatibilityTidy(url: url)
        
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
}

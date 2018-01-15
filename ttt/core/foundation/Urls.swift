//
//  Urls.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/15.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

final class Urls {
    /**
     * 获取url中除去host之后的path, 如果遇到 http://m.mymm.com/detail/{skuid}.html 类型，则匹配保留 detail/{_}.html
     * @param url
     * @return
     */
    public static func getURLFinderPath(url: String) -> String  {
        
        let uri = URL(string:url)
        
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
        let uri = URL(string:url)
        
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

//
//  Navigator.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/15.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit

/// Routing app all scene pages.
public final class Navigator: NSObject {
    
    // 私有化
    private override init() {
        super.init()
        loadConfig()
    }
    
    // singleton
    open static let shared = Navigator()
    
    /// add support scheme
    public func addScheme(scheme: String) {
        addSchemes(schemes: [scheme])
    }
    
    public func addSchemes(schemes: [String]) {
        for scheme in schemes {
            if _scheme.isEmpty {
                _scheme = scheme.lowercased()
            }
            _schemes.insert(scheme.lowercased())
        }
    }
    
    /// add support hosts
    public func addHost(host: String) {
        addHosts(hosts: [host])
    }
    
    public func addHosts(hosts: [String]) {
        for host in hosts {
            if _host.isEmpty {
                _host = host.lowercased()
            }
            _hosts.insert(host.lowercased())
        }
    }
    
    /// Comple url from path
    open func comple(path: String) -> String {
        if path.isEmpty {
            return path
        }
        var url = ""
        if path.contains("://") {
            url = path
        } else if path.starts(with: "/") {// is url
            url = _scheme + "://" + _host + path
        } else {
            url = _scheme + "://" + _host + "/" + path
        }
        return url
    }
    
    /// open url or open path
    open func open(path:String, params:Dictionary<String,Urls.QValue>? = nil, ext:Dictionary<String,NSObject>? = nil, modal:Bool = false) -> Bool {
        if path.isEmpty {
            return false
        }
        let url = comple(path: path)
        return open(url, params:params, modal:modal)
    }
    
    /// open url
    open func open(_ url:String, params:Dictionary<String,Urls.QValue>? = nil, ext:Dictionary<String,NSObject>? = nil, modal:Bool = false) -> Bool {
        if !isValid(url:url) {
            return false
        }
        
        // TODO
        
        return true
    }
    
    /// generate VC
    open func getViewController(path:String, params:Dictionary<String,Urls.QValue>? = nil, ext:Dictionary<String,NSObject>? = nil) -> UIViewController? {
        if path.isEmpty {
            return nil
        }
        let url = comple(path: path)
        return getViewController(url, params: params, ext: ext)
    }
    open func getViewController(_ url:String, params:Dictionary<String,Urls.QValue>? = nil, ext:Dictionary<String,NSObject>? = nil) -> UIViewController? {
        if !isValid(url:url) {
            return nil
        }
        
        let router = routerNode(url: url)
        if router == nil {
            return nil
        }
        
        var vc = router!.node.controller
        if vc.isEmpty {
            vc = "UIViewController"
        }
        
        let type = NSClassFromString(vc) as! UIViewController.Type
        let viewController = type.init()
        if let v = viewController as? MMUIController {
            v._node = router!.node
            v._uri = router!.id
            MMTry.try({ do {
                v.onInit(params: params, ext: ext)
            } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        }
        
        var cc = router!.node.container
        if cc.isEmpty && !(viewController is UINavigationController) {
            cc = "UINavigationController"
        }
        
        if !cc.isEmpty {
            let ctype = NSClassFromString(cc) as! UIViewController.Type
            let viewContainer = type.init()
//            if viewController
        }
        
        
        
        return nil
    }
    
    /// get router
    open func getRouter(url:String) -> VCNode? {
        return routerNode(url: url)?.node
    }
    fileprivate func routerNode(url:String) -> RouterNode? {
        let uri = Urls.getURLFinderPath(url:url)
        if uri.isEmpty {
            return nil
        }
        
        let node = _routers[uri]
        if (node != nil) {return node}
        
        //开始兼容其他形式，如 detail/{_}.html 或者 detail/{_}/{_}.html
        let strs = uri.split(separator: "/")
        var builder = ""
        for  i in (0..<strs.count).reversed() {
            //最后一个，需要特殊处理下
            let str = strs[i]
            if i == strs.count - 1 {
                let range = str.range(of: ".", options: .backwards)
                if range != nil {
                    builder.append("{_}");
                    builder.append(String(str[range!.lowerBound..<str.endIndex]))
                } else {
                    builder.append("{_}");
                }
            } else {
                builder.insert(contentsOf: "{_}/", at: builder.startIndex) // insert(0,"{_}/");//往前插入
            }
            
            var key = ""
            for j in 0..<i {
                key.append(String(strs[j]));
                key.append("/");
            }
            
            key.append(builder);
            let nn = _routers[key]
            if (nn != nil) { return nn }
        }
        
        return nil;
    }
    
    /// is valid url
    open func isValid(url:String) -> Bool {
        let uri = URL(string:Urls.encoding(url: url))
        
        if (uri == nil) {return false}
        
        let host = uri!.host
        if (host == nil || host!.isEmpty) {
            return false
        }
        
        let scheme = uri?.scheme
        if scheme == nil || scheme!.isEmpty {
            return false
        }
        
        return _schemes.contains(scheme!.lowercased()) && _hosts.contains(host!.lowercased())
    }
    
    // member var
    var _scheme: String = "" // default scheme
    var _host: String = ""  // default host
    var _schemes: Set<String> = Set<String>(minimumCapacity:3)
    var _hosts: Set<String> = Set<String>(minimumCapacity:2)
    var _routers: Dictionary<String,RouterNode> = Dictionary<String,RouterNode>()
    
    //
    private var _node: VCNode = VCNode()
}

class RouterNode: NSObject {
    var node: VCNode = VCNode()
    var id: String = ""// uri ≈≈≈ url.path
}

extension Navigator : XMLParserDelegate {
    func loadConfig() {
        let url = URL(fileURLWithPath: Bundle.main.path(forResource: "page_router", ofType: "xml")!)
        let parser = XMLParser(contentsOf: url as URL)
        //1
        parser!.delegate = self
        parser!.parse()
    }

    /*
    <items version="1.0">
        <item url="https://m.mymm.com/splash.html"
            key=""
            controller=""
            container="com.mm.main.app.StartActivity"
            description="启动页"/>
    </items>
    */
    
    // 1
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        if elementName == "item" {
            print("start parser:\(elementName)")
            _node = VCNode()
        }
    }
    
    // 2
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            print("end parser:\(elementName)")
            
            if _node.path.isEmpty || _node.url.isEmpty {
                return
            }
            
            let node = RouterNode()
            node.id = _node.path
            node.node = _node
            
            // add router
            _routers[node.id] = node
        }
    }
    
    public func parser(_ parser: XMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?) {
        
        if elementName == "item" {
            if attributeName == "url" && defaultValue != nil {
                _node.url = defaultValue!
                _node.path = Urls.getURLFinderPath(url: defaultValue!)
                _node.param = Urls.getURLPathParamKey(url: defaultValue!)
            } else if attributeName == "key" && defaultValue != nil {
                _node.key = defaultValue!
            } else if attributeName == "controller" && defaultValue != nil {
                _node.controller = defaultValue!
            } else if attributeName == "container" && defaultValue != nil {
                _node.container = defaultValue!
            } else if attributeName == "description" && defaultValue != nil {
                _node.des = defaultValue!
            }
        }
    }
    
//    // 3
//    public func parser(_ parser: XMLParser, foundCharacters string: String) {
//        let data = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
//
//        if (!data.isEmpty) {
//            if eName == "title" {
//                bookTitle += data
//            } else if eName == "author" {
//                bookAuthor += data
//            }
//        }
//    }
    
}




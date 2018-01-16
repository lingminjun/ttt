//
//  Navigator.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/15.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

/// Routing app all scene pages.
final class Navigator: NSObject {
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
    
    /// open url or open path
    public func open(path:String, params:Dictionary<String,Urls.QValue>? = nil, ext:Dictionary<String,NSObject>? = nil, modal:Bool = false) -> Bool {
        if path.isEmpty {
            return false
        }
        var url = ""
        if path.contains("://") {
            url = path
        } else if path.starts(with: "/") {// is url
            url = _scheme + "://" + _host + path
        } else {
            url = _scheme + "://" + _host + "/" + path
        }
        
        return open(url, params:params, modal:modal)
    }
    
    /// open url
    public func open(_ url:String, params:Dictionary<String,Urls.QValue>? = nil, ext:Dictionary<String,NSObject>? = nil, modal:Bool = false) -> Bool {
        if !isValid(url:url) {
            return false
        }
        
        // TODO
        
        return true
    }
    
    /// is valid url
    public func isValid(url:String) -> Bool {
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




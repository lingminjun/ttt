//
//  Navigator.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/15.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit

public let ROUTER_ON_BROWSER_KEY = "_on_browser"
public let ROUTER_MODAL_STYLE = "__modal";

public protocol Authorize {
    func authorized() -> Bool//当前是否认证过
    func howToAuthorize(url:String, query:Dictionary<String,QValue>) -> String//如何认证,返回认证的url
}

/// Routing app all scene pages.
public final class Navigator: NSObject {
    
    // private
    private override init() {
        super.init()
        loadConfig()
        UIViewController.router_hook()
        
        //add default schemes
    }
    
    private func addDefaultSchemes() {
        addHost(host: "https")
        addHosts(hosts: Navigator.appURLSchemes())
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
            var value = String(host.lowercased())
            var regex = false
            if host.contains("**") {
                // \w  [a-zA-Z_0-9]
                value = value.replacingOccurrences(of: "**", with: "[\\w|.]*")
                value = value.replacingOccurrences(of: ".", with: "\\.")
                regex = true
            } else if host.contains("*") {
                // \w  [a-zA-Z_0-9]
                value = value.replacingOccurrences(of: "*", with: "\\w+")
                value = value.replacingOccurrences(of: ".", with: "\\.")
                regex = true
            }
            
            //设置默认url
            if _host.isEmpty {
                if host.contains("**") {
                    var h = String(host.lowercased())
                    if h.contains("**.") {
                        h = h.replacingOccurrences(of: "**", with: "m")
                    } else {
                        h = h.replacingOccurrences(of: "**", with: "m.")
                    }
                    _host = h
                } else if host.contains("*") {
                    var h = String(host.lowercased())
                    h = h.replacingOccurrences(of: "*", with: "m")
                    _host = h
                } else {
                    _host = host.lowercased()
                }
            }
            
            _hosts.insert(HostMask(mask:host,value:value,regex:regex))
        }
    }
    
    /// set authorize, attention the reference
    public func setAuthorize(auth: Authorize) {
        _auth = auth
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
    open func open(path:String, params:Dictionary<String,QValue>? = nil, ext:Dictionary<String,NSObject>? = nil, modal:Bool? = false) -> Bool {
        if path.isEmpty {
            return false
        }
        let url = comple(path: path)
        return open(url, params:params, modal:modal)
    }
    
    private static func isSameKind(aClass: AnyClass, bClass: AnyClass) -> Bool {
        return aClass.isSubclass(of: bClass) || bClass.isSubclass(of: aClass)
    }
    
    /// do open url, no result
    open func dopen(_ url:String, params:Dictionary<String,QValue>? = nil, ext:Dictionary<String,NSObject>? = nil, modal:Bool? = nil) {
        let isOpen = open(url,params:params,ext:ext,modal:modal,inner:false)
        if !isOpen {
            print("open the url:\(url) failed!")
        }
    }
    
    /// open url
    open func open(_ url:String, params:Dictionary<String,QValue>? = nil, ext:Dictionary<String,NSObject>? = nil, modal:Bool? = nil, inner:Bool = false) -> Bool {
        if !isValid(url:url) {
            return false
        }
        var cc: String = ""
        var pd = false
        guard let vc = genViewController(url, params: params, ext: ext, checkAuth:true, pending:&pd, container: &cc) else {
            
            if pd {
                return true
            }
            
            if inner {
                return false
            }
            
            let u = URL(string:url)
            if u != nil {
                /*
                let scms = Navigator.appURLSchemes()
                let thescheme = u!.scheme
                if thescheme != nil && !scms.contains(thescheme!) && UIApplication.shared.canOpenURL(u!) {
                    var options = Dictionary<String,Any>()
                    if params != nil {
                        options = QValue.convert(query: params!)
                    }
                    UIApplication.shared.open(u!, options:options, completionHandler: { (result) in
                        print("open url \(url) result \(result)")
                    })
                    return true
                }
                 */
            }
            return false
        }
        var tc = topContainer()
        
        if cc.isEmpty && !(vc is UINavigationController) {
            cc = "UINavigationController"
        }
        
        //设置modal展示的值
        var isModal = false
        if modal != nil {
            isModal = modal!
        } else if let v = vc as? MMUIController {
            if v._node.modal != nil {
                isModal = v._node.modal!
            }
        }
        
        //open 主要是看top container和xml配置中是否同一个类型，若是，则不再new container
        if !cc.isEmpty {
            var xclazz = Navigator.reflectOCClass(name:cc)
            if xclazz != nil {
                let tclazz = type(of: tc) as Swift.AnyClass
                
                /// 不是同一个类型的或者是modal
                if !Navigator.isSameKind(aClass:xclazz!,bClass:tclazz) || isModal  {
                    MMTry.try({
                        tc = (Navigator.reflectViewController(name:cc) as? MMContainer)! //若不满足协议则构建失败
                    }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
                }
            }
        }
        
        tc.add(controller: vc, at: -1)
        
        //看看tc是否已经放入布局之中
        let ftc = topContainer(volatile: false)
        if tc !== ftc && tc is UIViewController {
            if isModal || ftc is UIViewController {
                (ftc as! UIViewController).present((tc as! UIViewController), animated: true, completion: nil)
            } else {
                ftc.add(controller: tc as! MMController, at: -1)
            }
        }
        
        return true
    }
    
    /// generate VC
    open func getViewController(path:String, params:Dictionary<String,QValue>? = nil, ext:Dictionary<String,NSObject>? = nil) -> UIViewController? {
        if path.isEmpty {
            return nil
        }
        let url = comple(path: path)
        return getViewController(url, params: params, ext: ext)
    }
    open func getViewController(_ url:String, params:Dictionary<String,QValue>? = nil, ext:Dictionary<String,NSObject>? = nil) -> UIViewController? {
        var temp = false
        var container = ""
        return genViewController(url, params: params, ext: ext, pending:&temp, container: &container)
    }
    fileprivate func genViewController(_ url:String, params:Dictionary<String,QValue>? = nil, ext:Dictionary<String,NSObject>? = nil, checkAuth:Bool = false, pending: inout Bool, container: inout String) -> UIViewController? {
        if !isValid(url:url) {
            return nil
        }
        
        // merge params
        var query = Urls.query(url: url)
        if params != nil {
            for (key,value) in params! {
                query[key] = value
            }
        }
        
        var router: RouterNode? = nil
        var hintParams = Dictionary<String,QValue>()
        let onBrowser = query[ROUTER_ON_BROWSER_KEY]
        if onBrowser != nil && onBrowser!.bool != nil && onBrowser!.bool! {
            router = RouterNode()
            router!.id = "/app/browser.html"
            router!.node = VCNode()
            router!.node.controller = "MMUIWebController"
            router!.node.url = comple(path: "/app/browser.html")
            var uurl = url
            if let v = query[LOAD_URL_KEY]?.string {
                uurl = v
            }
            
            router!.node.path = router!.id
            
            //Complement parameters
            var q = Urls.query(url: url);
            for (k,v) in query {
                if q[k] == nil && k != LOAD_URL_KEY  {
                    q[k] = v;
                }
            }
            
            query[LOAD_URL_KEY] = QValue(Urls.tidy(url: uurl, query: q))
            query.removeValue(forKey: ROUTER_ON_BROWSER_KEY)
        } else {
            router = routerNode(url: url, hintParams: &hintParams)
        }
        
        if router == nil {
            return nil
        }
        
        // url hide value; simple:https://m.mymm.com/s/{skuId}.html
        if !router!.node.param.isEmpty && hintParams.keys.contains(router!.node.param) {
            query[router!.node.param] = hintParams[router!.node.param]
        }
        
        // check auth
        if checkAuth && router!.node.auth {
            if _auth == nil { return nil } //无法验证
            pending = false
            
            //需要验证,且未登录
            if !_auth!.authorized() {
                _pendingUrl = Urls.tidy(url: url, query: query) //need append query
                _authUri = Urls.getURLFinderPath(url: _pendingUrl)
                _waiting = true
                let auth = _auth!.howToAuthorize(url: url, query: query)
                if auth.isEmpty {
                    _pendingUrl = ""
                    _waiting = false
                    return nil
                }
                
                if (!open(auth)) {
                    _pendingUrl = ""
                    _waiting = false
                    return nil
                }
                
                pending = true
                
                return nil
            }
        }
        
        //out param
        container = router!.node.container
        
        var vc = router!.node.controller
        if vc.isEmpty {
            vc = "UIViewController"
        }
        
        var viewController :UIViewController? = nil
        MMTry.try({
            viewController = Navigator.reflectViewController(name:vc)
            viewController?.title = router!.node.des
            viewController?.ssn_uri = router!.id
            viewController?.ssn_Arguments = query;
        }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        if viewController == nil {
            return nil
        }
        
        if let v = viewController as? MMUIController {
            v._node = router!.node
            MMTry.try({
                v.onInit(params: query, ext: ext)
            }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        }
        
        return viewController
    }
    
    private static func appURLSchemes() -> [String] {
        guard let schemes = Bundle.main.infoDictionary!["CFBundleURLTypes"] else { return [] }
        guard let list = schemes as? Array<Dictionary<String,Any>> else { return [] }
        var rs = [String]()
        for item in list {
            guard let scs = item["CFBundleURLSchemes"] else { continue }
            guard let ss = scs as? Array<String> else { continue }
            for str in ss {
                if !str.isEmpty {
                    rs.append(str)
                }
            }
        }
        return rs
    }
    
    private static func reflectOCClass(name:String) -> Swift.AnyClass? {
        guard let NameSpace = Bundle.main.infoDictionary!["CFBundleExecutable"] as? String else { return nil }
        
        var vcname = name
        if !name.contains(".") {
            vcname = NameSpace + "." + name
        }
        
        var clazz: Swift.AnyClass? = nil
        MMTry.try({
            clazz = NSClassFromString(vcname)
        }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        
        if clazz == nil {
            MMTry.try({
                clazz = NSClassFromString(name) //如果是系统看，则不需要取报名
            }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        }
        return clazz
    }
    private static func reflectViewController(name:String) -> UIViewController? {
        guard let clazz = reflectOCClass(name:name) else {return nil}
        let type = clazz as? UIViewController.Type
        return type?.init()
    }
    
    var _window : UIWindow = UIWindow()
    
    // launching
    open func launching(root window:UIWindow) {
        _window = window
    }
    
    /// get top container, default UINavigationController
    open func topContainer(volatile: Bool = true) -> MMContainer {
        let ctns = containers();
        if !volatile {
            return ctns.last!
        }
        for container in ctns.reversed() {
            if container.volatileContainer() {
                return container
            }
        }
        return ctns.first! //返回window
    }
    
    fileprivate func containers() -> [MMContainer] {
        var ctns = [] as [MMContainer]
        var container = _window as MMContainer
        ctns.append(container)
        while let vc = container.topController() {
            if vc is MMContainer {
                container = vc as! MMContainer
                ctns.append(container)
            } else {
                break
            }
        }
        return ctns
    }
    
    /// get router
    open func getRouter(url:String) -> VCNode? {
        var temp = Dictionary<String,QValue>()
        return routerNode(url: url, hintParams: &temp)?.node
    }
    
    
    fileprivate func routerNode(url:String, hintParams: inout Dictionary<String,QValue>) -> RouterNode? {
        let uri = Urls.getURLFinderPath(url:url)
        if uri.isEmpty {
            return nil
        }
        
        let node = _routers[uri]
        if (node != nil) {return node}
        
        ///开始兼容其他形式，如 detail/{_}.html 或者 detail/{_}/about.html 或者 detail/{_}/{_}.html
        
        /*//笛卡尔积，下面只选择已经标记
         detail/fff/ddd/ttt/{_}------1
         detail/fff/ddd/{_}/ooo------2
         detail/fff/{_}/ttt/ooo------3
         detail/{_}/ddd/ttt/ooo------4
         
         detail/kkk/lll/{_}/{_}------5
         detail/kkk/{_}/{_}/aaa------6
         detail/{_}/{_}/ddd/aaa------7
         detail/kkk/{_}/ddd/{_}
         detail/{_}/lll/{_}/aaa
         detail/{_}/lll/ddd/{_}
         
         detail/xxx/{_}/{_}/{_}------8
         detail/{_}/kkk/{_}/{_}
         detail/{_}/{_}/ddd/{_}
         detail/{_}/{_}/{_}/aaa------9
         
         detail/{_}/{_}/{_}/{_}------10
         */
        
        let range = uri.range(of: ".", options: .backwards)
        var paths:String = uri
        var ext:String = ""
        if range != nil {
            ext = String(uri[range!.lowerBound..<uri.endIndex])
            paths = String(uri[uri.startIndex..<range!.lowerBound]);
        }
        
        let strs = paths.split(separator: "/")
        var values = [] as [String];
        
        //需要查找的次数
        for times in (1..<strs.count).reversed() {//需要查找的次数
            
            let len = strs.count - times //替换长度
            
            //第几次查找
            for n in 1...times {
                var key:String = String(strs[0])
                values.removeAll()
                
                let start = strs.count - n - (len - 1) //开始替换位置
                
                //开始拼接key
                for j in 1..<strs.count {
                    if (j >= start && j < start + len) {//替换位置
                        key = key + "/{_}"
                        values.append(String(strs[j]))
                    } else {
                        key = key + "/" + strs[j]
                    }
                }
                
                key = key + ext
                
                //尝试取值
                guard let nn = _routers[key] else { continue }
                
                if !nn.node.param.isEmpty && values.count > 0 {
                    hintParams[nn.node.param] = QValue(values[0])
                }
                
                return nn
            }
        }
        
        /*
        for  i in (0..<strs.count).reversed() {
            //最后一个，需要特殊处理下
            let str = strs[i]
            if i == strs.count - 1 {
                let range = str.range(of: ".", options: .backwards)
                if range != nil {
                    builder.append("{_}");
                    builder.append(String(str[range!.lowerBound..<str.endIndex]))
                    
                    //暂时仅仅支持最后一个
                    values.append(String(str[str.startIndex..<range!.lowerBound]));
                } else {
                    builder.append("{_}");
                    
                    values.append(String(str));
                }
            } else {
                builder.insert(contentsOf: "{_}/", at: builder.startIndex) // insert(0,"{_}/");//往前插入
                
                values.append(String(str));
            }
            
            var key = ""
            for j in 0..<i {
                key.append(String(strs[j]));
                key.append("/");
            }
            
            key.append(builder);
            guard let nn = _routers[key] else { continue }
            
            if !nn.node.param.isEmpty && values.count > 0 {
                hintParams[nn.node.param] = QValue(values[0])
            }
            
            return nn
        }
        */
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
        
        if !_schemes.contains(scheme!.lowercased()) {
            return false
        }
        
        let h = host!.lowercased()
        for hst in _hosts {
            if hst.regex {
                let regex = NSPredicate(format: "SELF MATCHES %@", hst.value)
                if regex.evaluate(with: h) {
                    return true
                }
            } else {
                if h == hst.value {
                    return true
                }
            }
        }
        
        return false
    }
    
    fileprivate func checkAuthPending(vc:UIViewController) {
        if (_waiting && !_pendingUrl.isEmpty && !_authUri.isEmpty) {
            if (vc.ssn_uri == _authUri) {
                _waiting = false //表示等待结束
            }
        }
    }
    
    fileprivate func dealAuthPending(vc:UIViewController) {
        if (!_pendingUrl.isEmpty) {
            if (_auth == nil) { _pendingUrl = "" }
            if _auth!.authorized() {
                let url = _pendingUrl
                _pendingUrl = ""
                open(url)
            }
        }
    }
    
    // member var
    var _scheme: String = "" // default scheme
    var _host: String = ""  // default host
    var _schemes: Set<String> = Set<String>(minimumCapacity:3)
    var _hosts: Set<HostMask> = Set<HostMask>(minimumCapacity:2)
    var _routers: Dictionary<String,RouterNode> = Dictionary<String,RouterNode>()
    var _auth: Authorize? = nil  //
    var _waiting:Bool = false
    var _authUri = ""
    var _pendingUrl = ""//pending task that  will be open after authored
    
    //
    private var _node: VCNode = VCNode()
}

struct HostMask : Hashable {
    public var hashValue: Int { get { return self.mask.hashValue } }
    
    static func ==(lhs: HostMask, rhs: HostMask) -> Bool {
        return lhs.mask == rhs.mask
    }
    
    var mask = ""
    var value = ""
    var regex = false
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
            
            for (attributeName,attributeValue) in attributeDict {
                if attributeValue.isEmpty {
                    continue
                }
                if attributeName == "url" {
                    _node.url = attributeValue
                    _node.path = Urls.getURLFinderPath(url: attributeValue, config: true)
                    _node.param = Urls.getURLPathParamKey(url: attributeValue)
                } else if attributeName == "key" {
                    _node.key = attributeValue
                } else if attributeName == "controller" {
                    _node.controller = attributeValue
                } else if attributeName == "container" {
                    _node.container = attributeValue
                } else if attributeName == "description" {
                    _node.des = attributeValue
                } else if attributeName == "modal" {
                    _node.modal = QValue(attributeValue).bool
                } else if attributeName == "auth" {
                    guard let b = QValue(attributeValue).bool else { continue }
                    _node.auth = b;
                }
            }
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
    
//    public func parser(_ parser: XMLParser, foundAttributeDeclarationWithName attributeName: String, forElement elementName: String, type: String?, defaultValue: String?) {
//
//        if elementName == "item" {
//            if attributeName == "url" && defaultValue != nil {
//                _node.url = defaultValue!
//                _node.path = Urls.getURLFinderPath(url: defaultValue!)
//                _node.param = Urls.getURLPathParamKey(url: defaultValue!)
//            } else if attributeName == "key" && defaultValue != nil {
//                _node.key = defaultValue!
//            } else if attributeName == "controller" && defaultValue != nil {
//                _node.controller = defaultValue!
//            } else if attributeName == "container" && defaultValue != nil {
//                _node.container = defaultValue!
//            } else if attributeName == "description" && defaultValue != nil {
//                _node.des = defaultValue!
//            }
//        }
//    }
    
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

extension UIViewController {
    fileprivate class func router_hook() {
        // 确保不是子类
        if self !== UIViewController.self {
            return
        }
        
        router_swizzle_method(target: UIViewController.self, #selector(UIViewController.viewDidAppear(_:)), #selector(UIViewController.router_viewDidAppear(_:)))
        router_swizzle_method(target: UIViewController.self, #selector(UIViewController.viewDidDisappear(_:)), #selector(UIViewController.router_viewDidDisappear(_:)))
    }
    
    fileprivate class func router_swizzle_method(target: UIViewController.Type, _ left: Selector, _ right: Selector) {
        
        let originalMethod = class_getInstanceMethod(target, left)
        let swizzledMethod = class_getInstanceMethod(target, right)
        
        let didAddMethod = class_addMethod(target, left, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        
        if didAddMethod {
            class_replaceMethod(target, right, method_getImplementation(originalMethod!), method_getTypeEncoding(originalMethod!))
        } else {
            method_exchangeImplementations(originalMethod!, swizzledMethod!);
        }
    }
        
    @objc func router_viewDidAppear(_ animated: Bool) {
        self.router_viewDidAppear(animated)
        Navigator.shared.checkAuthPending(vc: self)
    }
    @objc func router_viewDidDisappear(_ animated: Bool) {
        Navigator.shared.dealAuthPending(vc: self)
        self.router_viewDidDisappear(animated)
    }
}



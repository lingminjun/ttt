//
//  MMWKWebController.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/19.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit
import WebKit


public class MMWKWebController: MMUIController,WKNavigationDelegate,WKUIDelegate {
    
    public var webView: WKWebView { get {return _web} }
    public var launchUrl: String { get { return _url } }
    public var currentUrl: String? { get { return _web.url?.absoluteString } }
    
    public override func onInit(params: QBundle?, ext: Dictionary<String, Any>?) {
        if let url = params?[LOAD_URL_KEY]?.string {
            _url = Urls.tidy(url: url)
        } else if let ext = ext, let v = ext[LOAD_URL_KEY], (v is String || v is Substring) {
            _url = "\(v)"
        }
    }
    
    public override func onLoadView() -> Bool {
        self.view = UIView(frame:UIScreen.main.bounds)
        
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        
        let configuration = WKWebViewConfiguration()
        configuration.preferences = preferences
        configuration.allowsInlineMediaPlayback = true
        if #available(iOS 9.0, *) {
            configuration.requiresUserActionForMediaPlayback = false
        } else {
            configuration.mediaPlaybackRequiresUserAction = false
        }
        
        _web = WKWebView(frame: self.view.bounds, configuration: configuration)
        _web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        _web.navigationDelegate = self
        _web.uiDelegate = self
        
        if #available(iOS 9.0, *) {//高于 iOS 9.0
            _web.customUserAgent = UserDefaults.standard.string(forKey: "UserAgent")
        }
        //https://stackoverflow.com/questions/32821677/how-to-autoscale-the-contents-of-a-wkwebview/33098927#33098927
//        _web.scalesPageToFit = true;
        
        self.view.addSubview(_web)
        return true
    }
    
    private final let WidthItemBar: CGFloat = 33
//    private final let PlaceHolderMinHeight : CGFloat = 166
    private final let HeightItemBar: CGFloat = 33
//    private final let OffsetAllowance = CGFloat(5)
    var shareButton = UIButton(type: .custom)
    
    public override func onViewDidLoad() {
        super.onViewDidLoad()
        
        // 右上角添加分享按钮
        shareButton.frame = CGRect(x:0, y: 0, width: WidthItemBar, height: HeightItemBar)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
        shareButton.setImage(UIImage(named:"share_black"), for: .normal)
        shareButton.track_consoleTitle = "分享"
        shareButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: CGFloat(-19))
        shareButton.clipsToBounds = false
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: shareButton)
        
        guard let url = URL(string: _url) else { return }
        var req = URLRequest(url: url)
        if #available(iOS 9.0, *) {} else {
            req.setValue(UserDefaults.standard.string(forKey: "UserAgent"), forHTTPHeaderField: "User-Agent")
        }
        req.setJWTHeader()
        _web.load(req)
    }
    
    @objc func shareButtonTapped() {
        let shareViewController = ShareViewController()
        
        var url = _url
        if let u = self.currentUrl {
            url = u
        }
        
        let model = CMSPageModel()
        model.link = url
        if let t = self.title {
            model.title = t
        } else {
            model.title = self.getShareDescription()
        }
        model.description = self.getShareDescription()
        model.coverImage = self.getShareIcon()
        
        shareViewController.didUserSelectedHandler = { [weak self] (data) in
            if let strongSelf = self {
                let myRole: UserRole = UserRole(userKey: Context.getUserKey())
                let targetRole: UserRole = UserRole(userKey: data.userKey)
                WebSocketManager.sharedInstance().sendMessage(
                    IMConvStartMessage(
                        userList: [myRole, targetRole],
                        senderMerchantId: myRole.merchantId
                    ),
                    checkNetwork: true,
                    viewController: strongSelf,
                    completion: { (ack) in
                        if let convKey = ack.data {
                            let chatModel = ChatModel(text: url)
                            let viewController = UserChatViewController(convKey: convKey)
                            viewController.forwardChatModel = chatModel
                            strongSelf.navigationController?.pushViewController(viewController, animated: true)
                        } else {
                            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                        }
                })
            }
        }
        
        shareViewController.didSelectSNSHandler = { method in
            //页面分享先套用cms模板，实际是Page模板
            ShareManager.sharedManager.shareCMSContentPage(model, method: method)
        }
        
        self.present(shareViewController, animated: false, completion: nil)
    }
    
    deinit {
        _web?.navigationDelegate = nil
        _web?.uiDelegate = nil
    }
    
    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let cred = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, cred)
    }
   
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        let allow = {
            if navigationAction.request.allHTTPHeaderFields?["Authorization"] != nil {
                decisionHandler(WKNavigationActionPolicy.allow)
            } else {
                decisionHandler(WKNavigationActionPolicy.cancel)
                var request = navigationAction.request
                request.setJWTHeader()
                webView.load(request)
            }
        }
        
        guard let url = navigationAction.request.url?.absoluteString else {
            allow()
            return
        }
        
        if url.isEmpty || url == "about:blank" {
            allow()
            return
        }
        
        switch navigationAction.navigationType {
        case .linkActivated, .other:
            if checkGotoOtherWebController(url: url) {
                allow()
            } else {
                decisionHandler(WKNavigationActionPolicy.cancel)
            }
            break
        default:
            allow()
            break
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if (!_wload) {
            _wload = true
        }
        self.title = webView.title
        
        // 加载meta
        DispatchQueue.main.async {
            self.getShareInfo()
        }
        
    }
    
    private func getShareInfo() {
        webView.evaluateJavaScript("try{document.querySelector('meta[name=\"share-description\"]').getAttribute('content');}catch(e){}",
                                   completionHandler:{ (ctn, err) in
            if let str = ctn as? String {
                self.jsOutSource(ctn:str, flag:"share-description")
            }
        })
        webView.evaluateJavaScript("try{document.querySelector('meta[name=\"description\"]').getAttribute('content');}catch(e){}",
                                   completionHandler:{ (ctn, err) in
            if let str = ctn as? String {
                self.jsOutSource(ctn:str, flag:"description")
            }
        })
        webView.evaluateJavaScript("try{document.querySelector('meta[name=\"share-icon\"]').getAttribute('content');}catch(e){}",
                                   completionHandler:{ (ctn, err) in
            if let str = ctn as? String {
                self.jsOutSource(ctn:str, flag:"share-icon")
            }
        })
        webView.evaluateJavaScript("try{document.querySelector('link[rel=\"apple-touch-icon-precomposed\"]').getAttribute('href');}catch(e){}", completionHandler:{ (ctn, err) in
            if let str = ctn as? String {
                self.jsOutSource(ctn:str, flag:"apple-touch-icon-precomposed")
            }
        })
        webView.evaluateJavaScript("try{document.querySelector('link[rel=\"apple-touch-icon\"]').getAttribute('href');}catch(e){}",
                                   completionHandler:{ (ctn, err) in
            if let str = ctn as? String {
                self.jsOutSource(ctn:str, flag:"apple-touch-icon")
            }
        })
        webView.evaluateJavaScript("try{document.querySelector('link[rel=\"shortcut icon\"]').getAttribute('href');}catch(e){}",
                                   completionHandler:{ (ctn, err) in
            if let str = ctn as? String {
                self.jsOutSource(ctn:str, flag:"shortcut icon")
            }
        })
    }
    
    private func jsOutSource(ctn:String, flag:String) {
        if ctn.isEmpty || ctn.lowercased() == "undefined" || ctn.lowercased() == "false" || ctn.lowercased() == "null" {
            return
        }
        
        if flag == "share-description" {
            _share_description = ctn
        } else if flag == "description" {
            _description = ctn
        } else if flag == "share-icon" {
            _share_icon = ctn
        } else if flag == "apple-touch-icon" && _touch_icon.isEmpty {
            _touch_icon = absolutelyUrl(path:ctn)
        } else if flag == "apple-touch-icon-precomposed" && _touch_icon.isEmpty {
            _touch_icon = absolutelyUrl(path:ctn)
        } else if flag == "shortcut icon" {
            _shortcut_icon = absolutelyUrl(path:ctn)
        }
    }
    
    private func absolutelyUrl(path:String) -> String {
        if path.starts(with: "http") {
            return path
        }
        
        if path.starts(with: "//") {
            var scheme = ""
            if let u = self.currentUrl {
                scheme = Urls.scheme(url: u)
            }
            if scheme.isEmpty {
                scheme = Urls.scheme(url: _url)
            }
            if scheme.isEmpty {
                scheme = "http"
            }
            return scheme + ":" + path
        }
        
        var location = ""
        if let u = self.currentUrl {
            location = Urls.location(url: u)
        }
        if location.isEmpty {
            location = Urls.location(url: _url)
        }
        if path.starts(with: "/") {
            return location + path
        } else {
            return location + "/" + path
        }
    }
    
    private func checkGotoOtherWebController(url: String) -> Bool {
        if Urls.isEqualURI(_url, url, scheme:true, host:true) {
            return true
        }
        
        /// 继承特殊参数
        var query = QBundle()
        if let sign = self.ssn_Arguments[ROUTER_HOST_SIGN] {
            query[ROUTER_HOST_SIGN] = sign
        }
        
        /// 委托导航器打开
        if Navigator.shared.open(url, params:query, inner:true) {
            return false
        } else if (!Navigator.shared.isValid(url: url)) {//不再加载
            return false
        }
        
        //无法Push到新的页面打开的话，就直接打开好了
        guard let nav = self.navigationController else { return true }
        
        //新的页面打开，体验更好
        let webv = MMWKWebController()
        webv._node = Navigator.shared.getWebRouterNode(url: url, query:query, webController:"MMWKWebController")
        webv._url = url
        webv.ssn_Arguments = query
        webv.onInit(params: query, ext: nil)
        nav.pushViewController(webv, animated: true)
        
        return false
    }
    
    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        //
    }
    
    // MARK: - WKUIDelegate
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Swift.Void) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default, handler: { (_) -> Void in
            // We must call back js
            completionHandler()
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Swift.Void) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default, handler: { (_) -> Void in
            completionHandler(true)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { (_) -> Void in
            completionHandler(false)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Swift.Void) {
        let alert = UIAlertController(title: prompt, message: defaultText, preferredStyle: .alert)
        
        alert.addTextField { (textField: UITextField) -> Void in
            textField.textColor = UIColor.red
        }
        alert.addAction(UIAlertAction(title: "好", style: .default, handler: { (_) -> Void in
            completionHandler(alert.textFields![0].text!)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func isWebLoaded() -> Bool {
        return _wload
    }
    
    func getShareDescription() -> String {
        if (!_share_description.isEmpty) {
            return _share_description
        }
        if (!_description.isEmpty) {
            return _description
        }
        if let title = self.title {
            return title
        }
        return ""
    }
    
    func getShareIcon() -> String {
        if (!_share_icon.isEmpty) {
            return _share_icon
        }
        if (!_touch_icon.isEmpty) {
            return _touch_icon
        }
        if (!_shortcut_icon.isEmpty) {
            return _shortcut_icon
        }
        return ""
    }
    
    // MARK: 属性
    private var _web: WKWebView!
    private var _url = "" // load url
    private var _wload = false
    
    // 分享相关字段
    private var _share_description = ""
    private var _description = ""
    private var _share_icon = ""
    private var _touch_icon = ""
    private var _shortcut_icon = ""
}

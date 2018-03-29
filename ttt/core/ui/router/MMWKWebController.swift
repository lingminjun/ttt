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
    
    public override func onInit(params: Dictionary<String, QValue>?, ext: Dictionary<String, Any>?) {
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
    
    public override func onViewDidLoad() {
        super.onViewDidLoad()
        
        guard let url = URL(string: _url) else { return }
        var req = URLRequest(url: url)
        if #available(iOS 9.0, *) {} else {
            req.setValue(UserDefaults.standard.string(forKey: "UserAgent"), forHTTPHeaderField: "User-Agent")
        }
        req.setJWTHeader()
        _web.load(req)
    }
    
    deinit {
        _web.navigationDelegate = nil
    }
    
    // MARK: - WKNavigationDelegate
    public func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        let cred = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, cred)
    }
   
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url?.absoluteString else {
            decisionHandler(WKNavigationActionPolicy.allow)
            return
        }
        
        if url.isEmpty || url == "about:blank" {
            decisionHandler(WKNavigationActionPolicy.allow)
            return
        }
        
        switch navigationAction.navigationType {
        case .linkActivated:
            if checkGotoOtherWebController(url: url) {
                decisionHandler(WKNavigationActionPolicy.allow)
            } else {
                decisionHandler(WKNavigationActionPolicy.cancel)
            }
            break
        default:
            decisionHandler(WKNavigationActionPolicy.allow)
            break
        }
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if (!_wload) {
            _wload = true
        }
        self.title = webView.title
    }
    
    
    private func checkGotoOtherWebController(url: String) -> Bool {
        if Urls.isEqualURI(_url, url, scheme:true, host:true) {
            return true
        }
        
        /// 继承特殊参数
        var query = Dictionary<String,QValue>()
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
    
    // MARK: 属性
    private var _web: WKWebView!
    private var _url = "" // load url
    private var _wload = false
}

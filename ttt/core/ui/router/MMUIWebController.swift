//
//  MMUIWebController.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/19.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit

public class MMUIWebController: MMUIController,UIWebViewDelegate {
    
    public var webView: UIWebView { get {return _web} }
    public var launchUrl: String { get { return _url } }
    public var currentUrl: String? { get { return _web.request?.url?.absoluteString } }
    
    public override func onInit(params: QBundle?, ext: Dictionary<String, Any>?) {
        if let url = params?[LOAD_URL_KEY]?.string {
            _url = Urls.tidy(url: url)
        } else if let ext = ext, let v = ext[LOAD_URL_KEY], (v is String || v is Substring) {
            _url = "\(v)"
        }
        
        //最后直接取 node url
        if _url.isEmpty {
            _url = self._node.url
        }
    }
    
    public override func onLoadView() -> Bool {
        self.view = UIView(frame:UIScreen.main.bounds)
        _web = UIWebView(frame:self.view.bounds)
        _web.scalesPageToFit = true;
//        _web.scrollView.isScrollEnabled = false
        _web.delegate = self
        _web.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        self.view.addSubview(_web)
        return true
    }
    
    public override func onViewDidLoad() {
        super.onViewDidLoad()
        
        guard let url = URL(string: _url) else { return }
        let req = URLRequest(url: url)
        _web.loadRequest(req)
    }
    
    deinit {
        _web?.delegate = nil
    }
    
    // MARK UIWebViewDelegate
    public func webViewDidStartLoad(_ webView: UIWebView) {
        //
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        if (!_wload) {
            _wload = true
        }
        if let title = _web.stringByEvaluatingJavaScript(from: "document.title"), !title.isEmpty {
            self.title = title
        }
    }
    
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        guard let url = request.url?.absoluteString else { return true }
        if url.isEmpty || url == "about:blank" {
            return true
        }
        
        print("should load \(url)")
        switch navigationType {
        case .linkClicked:
            return checkGotoOtherWebController(url: url)
//        case .other:
//            return checkGotoOtherWebController(url: url!)
        default:
            return true
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
        } else if (!Navigator.shared.isValid(url: url, params: query)) {//不再加载
            return false
        }
        
        //无法Push到新的页面打开的话，就直接打开好了
        guard let nav = self.navigationController else { return true }
        
        //新的页面打开，体验更好
        let webv = MMUIWebController()
        webv._node = Navigator.shared.getWebRouterNode(url: url, query:query, webController:"MMUIWebController")
        webv._url = url
        webv.ssn_Arguments = query
        webv.onInit(params: query, ext: nil)
        nav.pushViewController(webv, animated: true)
        
        return false
    }
    
    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        //
    }
    
    private var _web: UIWebView!
    private var _url = "" // load url
    private var _wload = false
}

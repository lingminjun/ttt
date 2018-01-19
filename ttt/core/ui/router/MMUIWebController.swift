//
//  MMUIWebController.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/19.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit

public let LOAD_URL_KEY = "_load_url"

public class MMUIWebController: MMUIController,UIWebViewDelegate {
    
    public var webView: UIWebView { get {return _web} }
    public var launchUrl: String { get { return _url } }
    public var currentUrl: String? { get { return _web.request?.url?.absoluteString } }
    
    public override func onInit(params: Dictionary<String, Urls.QValue>?, ext: Dictionary<String, Any>?) {
        var url = params?[LOAD_URL_KEY]?.string
        if url == nil && ext != nil {
            let v = ext![LOAD_URL_KEY]
            if v != nil && (v is String || v is Substring) {
                url = "\(v!)"
            }
        }
        
        if url != nil {
            _url = Urls.tidy(url: url!)
        }
    }
    
    public override func onLoadView() -> Bool {
        self.view = UIView(frame:UIScreen.main.bounds)
        _web = UIWebView(frame:self.view.bounds)
        _web.delegate = self
        self.view.addSubview(_web)
        return true
    }
    
    public override func onViewDidLoad() {
        super.onViewDidLoad()
        
        guard let url = URL(string: _url) else { return }
        let req = URLRequest(url: url)
        _web.loadRequest(req)
    }
    
    // MARK UIWebViewDelegate
    public func webViewDidStartLoad(_ webView: UIWebView) {
        //
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        if (!_wload) {
            _wload = true
        }
    }
    
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        let url = request.url?.absoluteString
        if url == nil || url!.isEmpty || url == "about:blank" {
            return true
        }
        print("should load \(url)")
        switch navigationType {
        case .linkClicked:
            return checkGotoOtherWebController(url: url!)
        case .other:
            return checkGotoOtherWebController(url: url!)
        default:
            return true
        }
    }
    
    private func checkGotoOtherWebController(url: String) -> Bool {
        if Urls.isEqualURI(_url, url) {
            return true
        }
        
        /// 判断
        
        /// 委托导航器打开
        if Navigator.shared.open(url) {
            return false
        }
        
        //无法Push到新的页面打开的话，就直接打开好了
        guard let nav = self.navigationController else { return true }
        
        //新的页面打开，体验更好
        let webv = MMUIWebController()
        webv._url = url
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

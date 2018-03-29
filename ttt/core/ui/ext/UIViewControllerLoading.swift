//
//  UIViewControllerLoading.swift
//  ttt
//
//  Created by MJ Ling on 2018/3/29.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

private let VC_LOAD_PANEL = ".VC_LOAD_PANEL"
private let VC_LOAD_FLAGS = ".VC_LOAD_FLAGS"
private let VC_LOAD_INDICATOR = ".VC_LOAD_INDICATOR"
extension UIViewController {
    private final var _loadPanel : UIView {
        get{
            guard let v = ssn_tag(VC_LOAD_PANEL) as? UIView else {
                let view = UIView()
                ssn_setTag(VC_LOAD_PANEL, tag: view)
                return view
            }
            return v
        }
        set{
            ssn_setTag(VC_LOAD_PANEL, tag: newValue)
        }
    }
    
    private final var _loadFlags : Set<String> {
        get{
            guard let v = ssn_tag(VC_LOAD_FLAGS) as? Set<String> else {
                let set = Set<String>()
                ssn_setTag(VC_LOAD_FLAGS, tag: set)
                return set
            }
            return v
        }
        set{
            ssn_setTag(VC_LOAD_FLAGS, tag: newValue)
        }
    }
    
    private final var _loadIndicator : UIActivityIndicatorView {
        get{
            guard let v = ssn_tag(VC_LOAD_INDICATOR) as? UIActivityIndicatorView else {
                let view = UIActivityIndicatorView()
                ssn_setTag(VC_LOAD_INDICATOR, tag: view)
                return view
            }
            return v
        }
        set{
            ssn_setTag(VC_LOAD_INDICATOR, tag: newValue)
        }
    }
    
    
    
    public final func showLoading(flag:String = ".default") {
        if self._loadFlags.contains(flag) { return }
        self._loadFlags.insert(flag)
        
        //绘制中间的loading
        self._loadPanel.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height:1)
        self._loadPanel.backgroundColor = .clear
        self._loadPanel.clipsToBounds = false
        if let _ = self._loadPanel.superview {
//            self.view.bringSubview(toFront: )
        } else {
            self.view.addSubview(self._loadPanel)
        }
        
        //绘制动画
        self._loadIndicator.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        self._loadIndicator.center = self.view.center
        self._loadIndicator.hidesWhenStopped = true
        self._loadIndicator.activityIndicatorViewStyle = .gray
        if let _ = self._loadIndicator.superview {
            
        } else {
            self._loadPanel.addSubview(self._loadIndicator)
        }
        self._loadIndicator.startAnimating()
    }
    
    public final func stopLoading(flag:String = ".default") {
        if !self._loadFlags.contains(flag) { return }
        
        self._loadFlags.remove(flag)
        
        if self._loadFlags.count > 0 {
            return
        }
        
        //隐藏 panel
        self._loadIndicator.stopAnimating()
        self._loadPanel.removeFromSuperview()
    }
}

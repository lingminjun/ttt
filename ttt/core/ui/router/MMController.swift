//
//  MMController.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/18.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit

@objc public protocol MMController {
//    func onInit(params: Dictionary<String,QValue>?, ext:Dictionary<String,Any>?)
    func onLoadView() -> Bool
    func onViewDidLoad() -> Void
    func onViewWillAppear(_ animated: Bool)
    func onViewDidAppear(_ animated: Bool)
    func onViewWillDisappear(_ animated: Bool)
    func onViewDidDisappear(_ animated: Bool)
    func onReceiveMemoryWarning()
}

@objc public protocol MMContainer : NSObjectProtocol{
    func topController() -> MMController?
    func childrenControllers() -> [MMController]
    func volatileContainer() -> Bool
    func add(controller:MMController, at:Int)
    func open(controller at:Int)
}

private var SSN_URI_PROPERTY = 0
private var VC_PARAMS_PROPERTY = 0

extension UIViewController: MMController {
    //The following is a safe life-cycle methods.
//    public func onInit(params: Dictionary<String,QValue>?, ext:Dictionary<String,Any>? = nil) {}
    public func onLoadView() -> Bool { return false }
    public func onViewDidLoad() -> Void { }
    public func onViewWillAppear(_ animated: Bool) { }
    public func onViewDidAppear(_ animated: Bool) { }
    public func onViewWillDisappear(_ animated: Bool) { }
    public func onViewDidDisappear(_ animated: Bool) { }
    public func onReceiveMemoryWarning() {}
    
    @objc public final var ssn_uri : String {
        get{
            guard let result = objc_getAssociatedObject(self, &SSN_URI_PROPERTY) as? String else {  return "" }
            return result
        }
        set{
            objc_setAssociatedObject(self, &SSN_URI_PROPERTY, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    //参数存储
    public final var ssn_Arguments : Dictionary<String,QValue>? {
        get{
            guard let result = objc_getAssociatedObject(self, &VC_PARAMS_PROPERTY) as? Dictionary<String,QValue> else {  return nil }
            return result
        }
        set{
            objc_setAssociatedObject(self, &VC_PARAMS_PROPERTY, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}

extension UINavigationController: MMContainer {
    public func volatileContainer() -> Bool {
        return true
    }
    
    public func topController() -> MMController? {
        return self.visibleViewController
    }
    
    public func childrenControllers() -> [MMController] {
        return self.viewControllers
    }
    
    public func add(controller: MMController, at: Int = -1) {
        if controller is UIViewController {
            var vs = self.viewControllers
            if at >= 0 && at < vs.count {
                vs.append((controller as! UIViewController))
                self.setViewControllers(vs, animated: false)
            } else {// push
                self.pushViewController((controller as! UIViewController), animated: true)
            }
        }
    }
    
    public func open(controller at: Int) {
        let vs = self.viewControllers
        if at >= 0 && at < vs.count {
            let vc =  vs[at]
            self.popToViewController(vc, animated: true)
        }
    }
}

extension UITabBarController: MMContainer {
    public func volatileContainer() -> Bool {
        return false
    }
    
    public func topController() -> MMController? {
        return self.selectedViewController
    }
    
    public func childrenControllers() -> [MMController] {
        guard let vs = self.viewControllers else { return [] }
        return vs
    }
    
    public func add(controller: MMController, at: Int = -1) {
        if controller is UIViewController {
            var vs = self.viewControllers
            if vs == nil {
                vs = []
            }
            if at >= 0 && at < vs!.count {
                vs!.insert((controller as! UIViewController), at: at)
            } else {
                vs!.append((controller as! UIViewController))
            }
        }
    }
    
    public func open(controller at: Int) {
        guard let vs = self.viewControllers else { return }
        if at >= 0 && at < vs.count {
            if at == self.selectedIndex {
                return
            }
            
            self.selectedIndex = at
        }
    }
    
}

extension UIWindow: MMContainer {
    public func volatileContainer() -> Bool {
        return false
    }
    
    public func topController() -> MMController? {
        return self.rootViewController
    }
    
    public func childrenControllers() -> [MMController] {
        let root = self.rootViewController
        if root == nil {
            return []
        }
        return [root!]
    }
    
    public func add(controller: MMController, at: Int) {
        if controller is UIViewController && self.rootViewController == nil {
            self.rootViewController = (controller as! UIViewController)
        }
    }
    
    public func open(controller at: Int) {
        //
    }
    
    
}

extension UIViewController {
    @objc public func theContainer() -> MMContainer? {
        let vc = self.navigationController
        if vc != nil {
            return vc!
        }
        
        let tv = self.tabBarController
        if tv != nil {
            return tv!
        }
        
        if (self.view.window?.rootViewController == self) {
            return self.view.window
        }
        
        return nil
    }
    
    public func ssn_back() {
        let nav = self.navigationController
        var presenting = self.presentingViewController
        
        if nav != nil {
            let idx = nav!.viewControllers.index(of: self)
            if idx != nil && idx! > 0 {
                nav!.popToViewController(nav!.viewControllers[idx!-1], animated: true)
                return
            }
            
            presenting = nav!.presentingViewController
        }
        
        if presenting != nil {
            presenting!.dismiss(animated: true, completion: nil)
        }
    }
}

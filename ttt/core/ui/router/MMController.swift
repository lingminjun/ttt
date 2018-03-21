//
//  MMController.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/18.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit

//VC初始化必须保留
public protocol MMUIControllerInitProtocol {
    //avoid not override the initialize
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)  // NS_DESIGNATED_INITIALIZER
}

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

@objc public protocol MMContainer : NSObjectProtocol {
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
    public final var ssn_Arguments : Dictionary<String,QValue> {
        get{
            guard let result = objc_getAssociatedObject(self, &VC_PARAMS_PROPERTY) as? Dictionary<String,QValue> else {  return [:] }
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
        if let vc = controller as? UIViewController {
            var vs = self.viewControllers
            if at >= 0 && at < vs.count {
                vs.append(vc)
                self.setViewControllers(vs, animated: false)
            } else {// push
                self.pushViewController(vc, animated: true)
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
        if let vc = controller as? UIViewController {
            var vs:[UIViewController] = []
            if let ovc = self.viewControllers {
                vs = ovc
            }
            if at >= 0 && at < vs.count {
                vs.insert(vc, at: at)
            } else {
                vs.append(vc)
            }
            
            self.setViewControllers(vs, animated: false)
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
        guard let root = self.rootViewController else { return [] }
        return [root]
    }
    
    public func add(controller: MMController, at: Int) {
        if let vc = controller as? UIViewController, self.rootViewController == nil {
            self.rootViewController = vc
        }
    }
    
    public func open(controller at: Int) {
        //
    }
    
    
}

extension UIViewController {
    @objc public func theContainer() -> MMContainer? {
        if let vc = self.navigationController {
            return vc
        }
        
        if let tv = self.tabBarController {
            return tv
        }
        
        if let window = self.view.window, window.rootViewController == self {
            return window
        }
        
        return nil
    }
    
    public func ssn_back() {
        let nav = self.navigationController
        var presenting = self.presentingViewController
        if let nav = nav {
            if let idx = nav.viewControllers.index(of: self), idx > 0 {
                nav.popToViewController(nav.viewControllers[idx-1], animated: true)
                return
            }
            
            presenting = nav.presentingViewController
        }
        
        presenting?.dismiss(animated: true, completion: nil)
    }
}

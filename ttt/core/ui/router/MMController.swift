//
//  MMController.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/18.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit

public protocol MMController {
    func onInit(params: Dictionary<String,Urls.QValue>?, ext:Dictionary<String,Any>?)
    func onLoadView() -> Bool
    func onViewDidLoad() -> Void
    func onViewWillAppear(_ animated: Bool)
    func onViewDidAppear(_ animated: Bool)
    func onViewWillDisappear(_ animated: Bool)
    func onViewDidDisappear(_ animated: Bool)
    func onReceiveMemoryWarning()
}

public protocol MMContainer {
    func topController() -> MMController?
    func childrenControllers() -> [MMController]
    func add(controller:MMController, at:Int?)
    func open(controller at:Int?)
}

extension UIViewController: MMController {
    //The following is a safe life-cycle methods.
    public func onInit(params: Dictionary<String,Urls.QValue>?, ext:Dictionary<String,Any>? = nil) {}
    public func onLoadView() -> Bool { return false }
    public func onViewDidLoad() -> Void { }
    public func onViewWillAppear(_ animated: Bool) { }
    public func onViewDidAppear(_ animated: Bool) { }
    public func onViewWillDisappear(_ animated: Bool) { }
    public func onViewDidDisappear(_ animated: Bool) { }
    public func onReceiveMemoryWarning() {}
}

extension UINavigationController: MMContainer {
    public func topController() -> MMController? {
        return self.visibleViewController
    }
    
    public func childrenControllers() -> [MMController] {
        return self.viewControllers
    }
    
    public func add(controller: MMController, at: Int?) {
        let vs = self.viewControllers
        if at == nil || at! > self.viewControllers.count {
            //
        }
    }
    
    public func open(controller at: Int?) {
        //
    }
    
    
}

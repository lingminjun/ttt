//
//  MMController.swift
//  merchant-ios
//
//  Created by MJ Ling on 2018/1/2.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

public class MMUIController : UIViewController,MMUIControllerInitProtocol {
    
    public override required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func onInit(params: QBundle?, ext:Dictionary<String,Any>? = nil) {}
    /*
    public func onLoadView() -> Bool { return false }
    public func onViewDidLoad() -> Void { }
    public func onViewWillAppear(_ animated: Bool) { }
    public func onViewDidAppear(_ animated: Bool) { }
    public func onViewWillDisappear(_ animated: Bool) { }
    public func onViewDidDisappear(_ animated: Bool) { }
    public func onReceiveMemoryWarning() {}
     */
    public func isVisible() -> Bool {
        switch _visible {
        case .didDisappear:
            return false
        default:
            return true
        }
    }
    
    //System life-cycle methods
    override final public func loadView() {
        if _stack_flag { return } else { _stack_flag = true }
        var rt = false
        MMTry.try({
            rt = self.onLoadView()
        }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
        _stack_flag = false
        if !rt {
            super.loadView()
        }
    }
    
    override final public func viewDidLoad() {
        if _stack_flag { return } else { _stack_flag = true }
        MMTry.try({
            self.onViewDidLoad()
        }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
        _stack_flag = false
        super.viewDidLoad();
    }
    
    override final public func viewWillAppear(_ animated: Bool) {
        if _stack_flag { return } else { _stack_flag = true }
        _visible = VisibleStatus.willAppear
        MMTry.try({
            self.onViewWillAppear(animated)
        }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
        _stack_flag = false
        super.viewWillAppear(animated)
    }
    
    override final public func viewDidAppear(_ animated: Bool) {
        if _stack_flag { return } else { _stack_flag = true }
        _visible = VisibleStatus.didAppear
        MMTry.try({
            self.onViewDidAppear(animated)
        }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
        _stack_flag = false
        super.viewDidAppear(animated)
    }
    
    override final public func viewWillDisappear(_ animated: Bool) {
        if _stack_flag { return } else { _stack_flag = true }
        MMTry.try({
            self.onViewWillDisappear(animated)
        }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
        _stack_flag = false
        super.viewWillDisappear(animated)
        _visible = VisibleStatus.willDisappear
    }
    
    override final public func viewDidDisappear(_ animated: Bool) {
        if _stack_flag { return } else { _stack_flag = true }
        MMTry.try({
            self.onViewDidDisappear(animated)
        }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
        _stack_flag = false
        super.viewDidDisappear(animated)
        _visible = VisibleStatus.didDisappear
    }
    
    override final public func didReceiveMemoryWarning() {
        MMTry.try({
            self.onReceiveMemoryWarning()
        }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - var
    private var _stack_flag = false
    
    private var _visible = VisibleStatus.didDisappear
    final func visible() -> VisibleStatus { return _visible }
    
    
    enum VisibleStatus {
        case didDisappear
        case willAppear
        case didAppear
        case willDisappear
    }
}

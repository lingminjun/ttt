//
//  MMController.swift
//  merchant-ios
//
//  Created by MJ Ling on 2018/1/2.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

public class MMUIController : UIViewController {
    
    
    public func onInit(params: Dictionary<String,Urls.QValue>?, ext:Dictionary<String,Any>? = nil) {}
    /*
    public func onLoadView() -> Bool { return false }
    public func onViewDidLoad() -> Void { }
    public func onViewWillAppear(_ animated: Bool) { }
    public func onViewDidAppear(_ animated: Bool) { }
    public func onViewWillDisappear(_ animated: Bool) { }
    public func onViewDidDisappear(_ animated: Bool) { }
    public func onReceiveMemoryWarning() {}
     */
    
    
    //System life-cycle methods
    override final public func loadView() {
        if _stack_flag { return } else { _stack_flag = true }
        var rt = false
        MMTry.try({ do {
            rt = try self.onLoadView()
        } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        _stack_flag = false
        if !rt {
            super.loadView()
        }
    }
    
    override final public func viewDidLoad() {
        if _stack_flag { return } else { _stack_flag = true }
        MMTry.try({ do {
            try self.onViewDidLoad()
        } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        _stack_flag = false
        super.viewDidLoad();
    }
    
    override final public func viewWillAppear(_ animated: Bool) {
        if _stack_flag { return } else { _stack_flag = true }
        MMTry.try({ do {
            try self.onViewWillAppear(animated)
        } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        _stack_flag = false
        super.viewWillAppear(animated)
    }
    
    override final public func viewDidAppear(_ animated: Bool) {
        if _stack_flag { return } else { _stack_flag = true }
        MMTry.try({ do {
            try self.onViewDidAppear(animated)
        } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        _stack_flag = false
        super.viewDidAppear(animated)
    }
    
    override final public func viewWillDisappear(_ animated: Bool) {
        if _stack_flag { return } else { _stack_flag = true }
        MMTry.try({ do {
            try self.onViewWillDisappear(animated)
        } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        _stack_flag = false
        super.viewWillDisappear(animated)
    }
    
    override final public func viewDidDisappear(_ animated: Bool) {
        if _stack_flag { return } else { _stack_flag = true }
        MMTry.try({ do {
            try self.onViewDidDisappear(animated)
        } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        _stack_flag = false
        super.viewDidDisappear(animated)
    }
    
    override final public func didReceiveMemoryWarning() {
        MMTry.try({ do {
            try self.onReceiveMemoryWarning()
        } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        super.didReceiveMemoryWarning()
    }
    
    var _stack_flag = false
    var _node = VCNode()
    var _uri = ""
    
    
}

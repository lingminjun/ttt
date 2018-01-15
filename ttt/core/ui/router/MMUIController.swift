//
//  MMController.swift
//  merchant-ios
//
//  Created by MJ Ling on 2018/1/2.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

public class MMUIController : UIViewController {
    
    //The following is a safe life-cycle methods.
    public func onInit(params: Dictionary<String,NSObject>?) {}
    public func onLoadView() -> Bool { return false }
    public func onViewDidLoad() -> Void { }
    public func onViewWillAppear(_ animated: Bool) { }
    public func onViewDidAppear(_ animated: Bool) { }
    public func onViewWillDisappear(_ animated: Bool) { }
    public func onViewDidDisappear(_ animated: Bool) { }
    public func onReceiveMemoryWarning() {}
    
    //System life-cycle methods
    override final public func loadView() {
        if _stack_flag { return } else { _stack_flag = true }
        var rt = false
        do {
            rt = try onLoadView()
        } catch {
            print("error:\(error)")
        }
        _stack_flag = false
        if !rt {
            super.loadView()
        }
    }
    
    override final public func viewDidLoad() {
        if _stack_flag { return } else { _stack_flag = true }
        do {
            try onViewDidLoad()
        } catch {
            print("error:\(error)")
        }
        _stack_flag = false
        super.viewDidLoad();
    }
    
    override final public func viewWillAppear(_ animated: Bool) {
        if _stack_flag { return } else { _stack_flag = true }
        do {
            try onViewWillAppear(animated)
        } catch {
            print("error:\(error)")
        }
        _stack_flag = false
        super.viewWillAppear(animated)
    }
    
    override final public func viewDidAppear(_ animated: Bool) {
        if _stack_flag { return } else { _stack_flag = true }
        do {
            try onViewDidAppear(animated)
        } catch {
            print("error:\(error)")
        }
        _stack_flag = false
        super.viewDidAppear(animated)
    }
    
    override final public func viewWillDisappear(_ animated: Bool) {
        if _stack_flag { return } else { _stack_flag = true }
        do {
            try onViewWillDisappear(animated)
        } catch {
            print("error:\(error)")
        }
        _stack_flag = false
        super.viewWillDisappear(animated)
    }
    
    override final public func viewDidDisappear(_ animated: Bool) {
        if _stack_flag { return } else { _stack_flag = true }
        do {
            try onViewDidDisappear(animated)
        } catch {
            print("error:\(error)")
        }
        _stack_flag = false
        super.viewDidDisappear(animated)
    }
    
    override final public func didReceiveMemoryWarning() {
        do {
            try onReceiveMemoryWarning()
        } catch {
            print("error:\(error)")
        }
        super.didReceiveMemoryWarning()
    }
    
    var _stack_flag = false
}

//
//  RigidCache.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/23.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

public class RigidCache<T: Equatable> {
    
    private class WeakBox<T> {
        private weak var _obj:AnyObject?
        init(_ obj:T) {
            _obj = (obj as AnyObject)
        }
        func get() -> T? {
            return _obj as? T
        }
    }
    
    private var _creator:((_ key:String, _ info:Dictionary<String,Any>?) -> T)!
    private var _hold:CycleStack<T>!
    private var _cache:Dictionary<String,WeakBox<T>>!
    
    public init(_ creator:@escaping (_ key:String, _ info:Dictionary<String,Any>?) -> T, size:UInt = 3) {
        _creator = creator
        var sz = Int(size)
        if sz == 0 {
            sz = 3
        }
        _hold = CycleStack<T>(sz)
        _cache = Dictionary<String,WeakBox<T>>(minimumCapacity:sz)
    }
    
    public func get(_ key:String, info:Dictionary<String,Any>? = nil) -> T? {
        objc_sync_enter(self)
        let obj = sync_get(key,info: info)
        objc_sync_exit(self)
        return obj
    }
    
    private func sync_get(_ key:String, info:Dictionary<String,Any>? = nil) -> T? {
        if let box = _cache[key] {
            if let obj = box.get() {
                return obj
            } else {
                _cache.removeValue(forKey: key)
            }
        }
        
        var obj:T? = nil
        MMTry.try({
            obj = self._creator(key,info)
        }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
        
        // cache
        if let obj = obj {
            _ = _hold.push(obj)
            _cache[key] = WeakBox(obj)
        }
        
        return obj
    }
}

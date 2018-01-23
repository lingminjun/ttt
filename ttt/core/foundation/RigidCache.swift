//
//  RigidCache.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/23.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation


public class RigidCache<T: NSObject> {
    
    class WeakBox<T: AnyObject> {
        private weak var _obj:T?
        init(_ obj:T) {
            _obj = obj
        }
        func get() -> T? {
            return _obj
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
        let box = _cache[key]
        if box != nil {
            let obj = box!.get()
            if obj != nil {
                return obj!
            } else {
                _cache.removeValue(forKey: key)
            }
        }
        
        var obj:T? = nil
        MMTry.try({ do {
            obj = try self._creator(key,info)
        } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        
        // cache
        if obj != nil {
            _hold.push(obj!)
            _cache[key] = WeakBox(obj!)
        }
        
        return obj
    }
}

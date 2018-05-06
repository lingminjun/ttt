//
//  KeyCycleStack.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/23.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

public final class KeyCycleStack<K: Hashable,T: AnyObject> {
    private var _keys:[K?] = []
    private var _stack:Dictionary<K,T> = Dictionary()
    private var _idx:Int = 0
    private var MAX_SIZE:Int = 10
    
    public init(_ size:Int) {
        MAX_SIZE = size < 0 ? 10 : size
        //初始化大小
        for _ in 0..<MAX_SIZE {
            _keys.append(nil)
        }
    }
    
    /**
     * 压入栈顶
     * @param key 不允许为空
     * @param obj 不允许为空
     * @return
     */
    public func push(_ key:K,_ obj:T) -> T {
        
        if let oldKey = _keys[_idx % MAX_SIZE] {
            _stack.removeValue(forKey: oldKey)
        }
        
        _keys[_idx % MAX_SIZE] = key//替换栈顶元素
        _stack[key] = obj
        
        _idx = ((_idx + 1) % MAX_SIZE)
        return obj;
    }
    
    /**
     * 移除栈顶
     * @return
     */
    public func pop() -> T? {
        _idx = (_idx + MAX_SIZE - 1) % MAX_SIZE
        let key = _keys[_idx % MAX_SIZE]//取出栈顶元素
        _keys[_idx % MAX_SIZE] = nil
        
        var obj:T? = nil
        if let key = key {
            obj = _stack.removeValue(forKey: key)
        }
        return obj;
    }
    
    /**
     * 栈顶元素
     * @return
     */
    public func top() -> T? {
        let idx = (_idx + MAX_SIZE - 1) % MAX_SIZE
        let key = _keys[idx % MAX_SIZE]//取出栈顶元素
        
        var obj:T? = nil
        if let key = key {
            obj = _stack[key]
        }
        return obj;
    }
    
    /**
     * 栈底元素
     * @return
     */
    public func bottom() -> T? {
        for i in 0..<MAX_SIZE {
            let idx = (_idx + i) % MAX_SIZE
            if let key = _keys[idx % MAX_SIZE] {
                return _stack[key]
            }
        }
        return nil
    }
    
    /**
     * 栈内元素个数
     * @return
     */
    public func size() -> Int {
        //满栈
        if (_keys[_idx % MAX_SIZE] != nil) {
            return MAX_SIZE;
        }
        
        //计算个数
        var index = 1
        for i in 1..<MAX_SIZE {
            
            let idx = (_idx + MAX_SIZE - i) % MAX_SIZE
            if let _ = _keys[idx % MAX_SIZE] {//取出栈顶元素
            } else {
                index = idx
                break
            }
        }
        return index - 1
    }
    
    /**
     * 移除栈顶
     * @return
     */
    public func pop(_ key:K) -> T? {
        
        var fond = false
        for i in 1...MAX_SIZE {
            
            let idx = (_idx + MAX_SIZE - i) % MAX_SIZE
            guard let akey = _keys[idx % MAX_SIZE] else {//取出栈顶元素
                break
            }
            
            //找到对应的数据
            if (!fond && akey == key) {
                fond = true;
                
                //开始移位排序
                for j in 1..<i {
                    _keys[(idx + j - 1 + MAX_SIZE) % MAX_SIZE] = _keys[(idx + j) % MAX_SIZE]
                }
                _keys[(idx + i - 1) % MAX_SIZE] = nil//最后将数据提前
                
                break;
            }
        }
        
        var obj:T? = nil
        if (fond) {//取出栈顶元素
            _idx = (_idx + MAX_SIZE - 1) % MAX_SIZE
            _keys[_idx % MAX_SIZE] = nil
            obj = _stack.removeValue(forKey: key)
            
        }
        
        return obj
    }
    
    /**
     * 移除栈顶key，若有多个同名key时，保留其value，效率比pop要低
     * @return
     */
    public func pop_key() -> T? {
        _idx = (_idx + MAX_SIZE - 1) % MAX_SIZE
        let key = _keys[_idx % MAX_SIZE]//取出栈顶元素
        _keys[_idx % MAX_SIZE] = nil
        
        var obj:T? = nil
        if let key = key {
            obj = _stack[key]
            if (!contains(key, andValue:true)) {
                _stack.removeValue(forKey: key)
            }
        }
        return obj
    }
    
    /**
     * 移除对应的key，若有多个同名key时，保留其value，效率比pop要低
     * @return
     */
    public func pop_key(_ key:K) -> T? {
        var fond = false
        for i in 1...MAX_SIZE {
            
            let idx = (_idx + MAX_SIZE - i) % MAX_SIZE
            guard let akey = _keys[idx % MAX_SIZE] else { break }//取出栈顶元素
            
            //找到对应的数据
            if (!fond && akey == key) {
                fond = true;
                
                //开始移位排序
                for j in 1..<i {
                    _keys[(idx + j - 1 + MAX_SIZE) % MAX_SIZE] = _keys[(idx + j) % MAX_SIZE]
                }
                _keys[(idx + i - 1) % MAX_SIZE] = nil//最后将数据提前
                
                break
            }
        }
        
        var obj:T? = nil
        if (fond) {//取出栈顶元素
            _idx = (_idx + MAX_SIZE - 1) % MAX_SIZE
            _keys[_idx % MAX_SIZE] = nil
            
            //遍历栈，看是否仍然存在同名key
            obj = _stack[key]
            if (!contains(key, andValue: true)) {
                _stack.removeValue(forKey: key)
            }
        }
        
        return obj
    }
    
    /**
     * 表示栈满
     * @return
     */
    public func isFull() -> Bool {
        return _keys[_idx % MAX_SIZE] != nil//表示是满栈
    }
    
    /**
     * 清空栈
     * @return list 是 fifo
     */
    public func clear() -> [T] {
        var list = [T]()
        for _ in 0..<MAX_SIZE {
            if let obj = pop() {
                list.insert(obj, at: 0)//保持原有顺序
            }
        }
        return list;
    }
    
    /**
     * 复制栈
     * @return list 是 fifo
     */
    public func toList() -> [T] {
        var list = [T]()
        for i in 1...MAX_SIZE {
            
            let idx = (_idx + MAX_SIZE - i) % MAX_SIZE
            guard let key = _keys[idx % MAX_SIZE] else { break } //取出栈顶元素
            
            if let obj = _stack[key] {
                list.insert(obj, at: 0)//保持原有顺序
            }
        }
        return list;
    }
    
    /**
     * 逆向复制栈
     * @return list与栈顺序一致
     */
    public func toReverseList() -> [T] {
        var list = [T]()
        for i in 1...MAX_SIZE {
            
            let idx = (_idx + MAX_SIZE - i) % MAX_SIZE
            guard let key = _keys[idx % MAX_SIZE]  else { break } //取出栈顶元素
            
            if let obj = _stack[key] {
                list.append(obj)//保持原有顺序
            }
        }
        return list;
    }
    
    /**
     * 包含某个元素
     * @param key
     * @return
     */
    public func contains(_ key:K, andValue:Bool = false) -> Bool {
        if !andValue {
            return _stack.keys.contains(key)
        }
        
        //从栈顶开始取，直到取到为null为止
        for i in 1...MAX_SIZE {
            let idx = (_idx + MAX_SIZE - i) % MAX_SIZE
            guard let o = _keys[idx % MAX_SIZE] else { break }//取出栈顶元素
            if o == key {
                return true
            }
        }
        
        return false
    }
    
    
    /**
     * 获取某个元素
     * @param key
     * @return
     */
    public func get(_ key:K) -> T? {
        return _stack[key]
    }
}

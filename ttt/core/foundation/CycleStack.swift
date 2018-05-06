//
//  CycleStack.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/23.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

public final class CycleStack<T: Equatable> {
    private var _stack:[T?] = []
    private var _idx: Int = 0
    private var MAX_SIZE:Int = 10
    
    public init(_ size:Int) {
        MAX_SIZE = size < 0 ? 10 : size
        //初始化大小
        for _ in 0..<MAX_SIZE {
            _stack.append(nil)
        }
    }
    
    /**
     * 压入栈顶
     * @param obj
     * @return
     */
    public func push(_ obj:T) -> T {
        _stack[_idx%MAX_SIZE] = obj //替换栈顶元素
        _idx = ((_idx + 1)%MAX_SIZE)
        return obj;
    }
    
    /**
     * 移除栈顶
     * @return
     */
    public func pop() -> T? {
        _idx = (_idx + MAX_SIZE - 1)%MAX_SIZE;
        let obj = _stack[_idx%MAX_SIZE] //取出栈顶元素
        _stack[_idx % MAX_SIZE] = nil //
        return obj;
    }
    
    /**
     * 栈顶元素
     * @return
     */
    public func top() -> T? {
        let idx = (_idx + MAX_SIZE - 1) % MAX_SIZE;
        let obj = _stack[idx % MAX_SIZE];//取出栈顶元素
        return obj;
    }
    
    /**
     * 栈底元素
     * @return
     */
    public func bottom() -> T? {
        for i in 0..<MAX_SIZE {
            let idx = (_idx + i) % MAX_SIZE
            let obj = _stack[idx % MAX_SIZE] //取出栈底元素
            if obj != nil { return obj }
        }
        return nil;
    }
    
    /**
     * 栈内元素个数
     * @return
     */
    public func size() -> Int {
        //满栈
        if (_stack[_idx % MAX_SIZE] != nil) {
            return MAX_SIZE;
        }
        
        //计算个数
        var index = 1
        for i in 1...MAX_SIZE {
            
            let idx = (_idx + MAX_SIZE - i) % MAX_SIZE
            let obj = _stack[idx % MAX_SIZE];//取出栈顶元素
            
            if (obj == nil) {
                index = i
                break
            }
        }
        
        return index - 1
    }
    
    /**
     * 表示栈满
     * @return
     */
    public func isFull() -> Bool {
        return _stack[_idx % MAX_SIZE] != nil//表示是满栈
    }
    
    /**
     * 清空栈
     * @return list 是 fifo
     */
    public func clear() -> [T] {
        var list = [T]()
        for _ in 0..<MAX_SIZE {
            if let obj = pop() {
                list.insert(obj, at: 0) //保持原有顺序
            } else { break }
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
            
            let idx = (_idx + MAX_SIZE - i) % MAX_SIZE;
            if let obj = _stack[idx % MAX_SIZE] {
                list.insert(obj, at: 0) //保持原有顺序
            } else { break }
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
            
            let idx = (_idx + MAX_SIZE - i) % MAX_SIZE;
            if let obj = _stack[idx % MAX_SIZE] {
                list.append(obj) //保持原有顺序
            } else { break }
        }
        return list;
    }
    
    /**
     * 包含某个元素
     * @param obj
     * @return
     */
    public func contains(_ obj: T) -> Bool {
        //从栈顶开始取，直到取到为null为止
        for i in 1...MAX_SIZE {
            let idx = (_idx + MAX_SIZE - i) % MAX_SIZE
            if let o = _stack[idx % MAX_SIZE] {
                if (o == obj) {
                    return true;
                }
            } else { break }
        }
        
        return false;
    }
    
    /**
     * 压入栈顶，并更新至栈顶
     * @param obj
     * @return
     */
    public func update_push(_ obj:T) -> T  {
        
        for i in 1...MAX_SIZE {
            let idx = (_idx + MAX_SIZE - i) % MAX_SIZE;
            if let o = _stack[idx % MAX_SIZE] {//取出栈顶元素
                if (o == obj) {//开始移位排序
                    for j in 1..<i {
                        _stack[(idx + j - 1 + MAX_SIZE) % MAX_SIZE] = _stack[(idx + j) % MAX_SIZE];
                    }
                    _stack[(idx + i - 1) % MAX_SIZE] = o//最后将数据提前
                    return obj;
                }
            } else { break }
        }
        
        //不包含则直接压入栈顶
        _stack[_idx % MAX_SIZE] = obj//替换栈顶元素
        _idx = ((_idx + 1) % MAX_SIZE)
        return obj;
    }

}

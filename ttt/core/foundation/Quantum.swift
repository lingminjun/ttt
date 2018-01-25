//
//  Quantum.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/24.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

public let QUANTUM_DEFAULT_MAX_COUNT = 100
public let QUANTUM_DEFAULT_INTERVAL = UInt64(100) //0.1毫秒


public class Quantum<T: Equatable> {
    
    public typealias Express = (Quantum<T>, [T]) throws -> Void
    
    /**
     * 构造函数
     * @param count
     * @param interval
     */
    public init(count:Int, interval:UInt64, express:Express? = nil) {
        _maxCount = count <= 0 ? QUANTUM_DEFAULT_MAX_COUNT : count
        _interval = interval <= 0 ? QUANTUM_DEFAULT_INTERVAL : interval
        _stack = CycleStack<T>(_maxCount)
        _express = express
    }
    
    /**
     * push数据
     * @param obj
     */
    public func push(_ obj:T) {
        
        _block?.cancel()
        _block = generateBlock()
        _stack.push(obj);
        
        if (_stack.isFull()) {//直接播发
            let objs = _stack.toList()
            _stack.clear()
            express(objs)
        } else {//延后播发
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.init(uptimeNanoseconds: _interval * 1000), execute: _block!)
        }
    }
    
    /**
     * 若一次push数据超过 maxCount，播发数据将会立即出发，数量为当前数量（大于maxCount）
     * @param objs
     */
    public func pushAll(_ objs:[T]) {
        if (objs.isEmpty) {return}
        
        _block?.cancel()
        _block = generateBlock()
        
        var list:[T]? = nil
        for obj in objs {
            if (list != nil) {//说明栈已经满，为了节约播发次数，不做拆分，一次播放
                list!.append(obj);
                continue;
            }
            
            _stack.push(obj);
            
            if (_stack.isFull()) {//满了后，直接赋值给list
                list = _stack.toList();
                _stack.clear();
            }
        }
        
        if (list != nil) {
            express(list!);
        } else {//延后播发
            DispatchQueue.main.asyncAfter(deadline: DispatchTime(uptimeNanoseconds: _interval * 1000), execute: _block!)
        }
    }
    
    /**
     * 最大播发数量
     * @return
     */
    public func getMaxCount() -> Int {return _maxCount;}
    
    /**
     * 间隔时间
     * @return
     */
    public func getInterval() -> UInt64 {return _interval}
    
    /**
     * 设置播放器实现
     * @param express
     */
    public func setExpress(_ express:@escaping Express) {
        _express = express;
    }
    
    
    private func express(_ objs:[T]) {
        if (objs.isEmpty) { return }
        
        if (_express != nil) {
            MMTry.try({ do {
                try self._express!(self,objs);
            } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        } else {
            print("no express! ")
        }
    }

    private func generateBlock() -> DispatchWorkItem {
        let item = DispatchWorkItem(block: { [weak self] () in // 创建一个block，block的标志是DISPATCH_BLOCK_INHERIT_QOS_CLASS
            guard let objs = self?._stack.toList() else {return}
            self?._stack.clear();
            self?.express(objs);
        })
        return item
    }
    
    private var _maxCount:Int;
    private var _interval:UInt64;//mis
    
    private var _stack:CycleStack<T>!//采用循环栈存储数据
    private var _express:Express? = nil
    private var _block:DispatchWorkItem? = nil // cycle reference
}

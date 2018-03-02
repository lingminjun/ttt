//
//  MMFetchList.swift
//  merchant-ios
//
//  Created by MJ Ling on 2018/1/8.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation


/// 普通列表管理
public class MMFetchList<T: MMCellModel>: MMFetch<T> {
    var _list = [T]()
    
    override public init(tag:String) {
        super.init(tag: tag)
    }
    
    public init(list:[T]?) {
        super.init(tag:"list:")
        if let list = list {
            _list = list
        }
    }
    
    /// Derived class implements
    public override func count() -> Int {return _list.count}
    public override func objects/*<S: SequenceType where S.Generator.Element: Object>*/() -> [T]? { return Array(_list)}
    
    /// Update
    override public func update(_ idx: Int, _ b: (() throws -> Void)?) {
        guard let obj = self[idx] else {return}
        _listener?.ssn_fetch_begin_change(self)
        _listener?.ssn_fetch(self,didChange: obj, at:idx, for: MMFetchChangeType.update, newIndex:idx)
        if let b = b {
            MMTry.try({ do {
                try b()
            } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
        }
        _listener?.ssn_fetch_end_change(self)
    }
    /// Insert `newObject` at index `i`. Derived class implements.
    public override func insert<C: Sequence>(_ newObjects: C, atIndex i: Int) where C.Iterator.Element == T {
        var idx = i
        //compatibility out boundary
        if i < 0 || i > _list.count {
            idx = _list.count
        }
        
        _listener?.ssn_fetch_begin_change(self)
        
        for obj in newObjects {
            let at = idx
            idx += 1
            _list.insert(obj, at: at)
            _listener?.ssn_fetch(self,didChange: obj, at: at, for: MMFetchChangeType.insert, newIndex: at)
        }
//        for ii in 0..<newObjects.underestimatedCount {
//            _list.insert(newObjects[ii], at: ii + idx)
//            _listener?.ssn_fetch(self,didChange: newObjects[ii], at: ii + idx, for: MMFetchChangeType.insert, newIndex: ii + idx)
//        }
        
        _listener?.ssn_fetch_end_change(self)
        
    }
    
    /// Remove and return the element at index `i`. Derived class implements.
    public override func delete(_ index: Int) -> T? {
        if index < 0 || index >= _list.count {
            return nil
        }
        
        let obj = _list.remove(at: index)
        _listener?.ssn_fetch(self,didChange: obj, at: index, for: MMFetchChangeType.delete, newIndex: index)
        return obj
    }
    public override func delete(_ index: Int, length: Int) {
        if index < 0 || index >= _list.count {
            return
        }
        
        _listener?.ssn_fetch_begin_change(self)
        
        for ii in (0..<length).reversed() {
            
            if index < 0 || index >= _list.count {
                continue
            }
            
            let obj = _list.remove(at: ii)
            
            _listener?.ssn_fetch(self,didChange: obj, at: ii, for: MMFetchChangeType.delete, newIndex: ii)
        }
        
        _listener?.ssn_fetch_end_change(self)

    }
    
    
    /// Remove all elements. Derived class implements.
    public override func clear() {
        if _list.isEmpty {
            return
        }
        
        _listener?.ssn_fetch_begin_change(self)
        
        for ii in (0..<_list.count).reversed() {
            
            let obj = _list.remove(at: ii)
            
            _listener?.ssn_fetch(self,didChange: obj, at: ii, for: MMFetchChangeType.delete, newIndex: ii)
        }
        
        _listener?.ssn_fetch_end_change(self)

    }
    
    /// Get element at index. Derived class implements.
    public override func get(_ index: Int) -> T? {
        if index < 0 || index >= _list.count {
            return nil
        }
        
        return _list[index]
    }
    
    /// Returns the index of an object in the results collection. Derived class implements.
    public override func indexOf(_ object: T) -> Int? {
        for idx in 0..<_list.count {
            if _list[idx] === object {// FIX ME
                return idx;
            }
        }
//        if object is Equatable {
//            return _list.indexOf(object)
//        }
        return nil
    }
    public override func filter(_ predicate: NSPredicate) -> [T] {
        return _list.filter({ (obj) -> Bool in
            return predicate.evaluate(with: obj)
        })
    }

    
}

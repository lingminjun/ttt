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
    public override func update(_ idx: Int, newObject: T? = nil, animated:Bool? = nil) {
        self.operation(updates: { (section) -> [IndexPath] in
            guard let _ = self[idx] else { return [] }
            if let nobj = newObject {
                self._list[idx] = nobj
            }
            return [IndexPath(row:idx,section:section)]
        }, animated:animated)
    }
    /// Insert `newObjects` at index `i`. Derived class implements.
    public override func insert<C: Sequence>(_ newObjects: C, atIndex i: Int, animated:Bool? = nil) where C.Iterator.Element == T {
//        var c = 0; for _ in newObjects { c += 1 }
        self.operation(inserts: { (section) -> [IndexPath] in
            
            var idx = i
            //compatibility out boundary
            if i < 0 || i > self._list.count {
                idx = self._list.count
            }
            
            var results:[IndexPath] = []
            for obj in newObjects {
                let at = idx
                self._list.insert(obj, at: at)
                results.append(IndexPath(row:at,section:section))
                idx += 1
            }
            return results
        }, animated:animated)
    }
    
    /// reset `newObjects`. Derived class implements.
    public override func reset<C>(_ newObjects: C, animated:Bool? = nil) where T == C.Element, C : Sequence {
        self.operation(deletes: { (section) -> [IndexPath] in
            if self._list.isEmpty {
                return []
            }
            
            var results:[IndexPath] = []
            for ii in (0..<self._list.count).reversed() {
                self._list.remove(at: ii)
                results.append(IndexPath(row:ii,section:section))
            }
            return results
        }, inserts: { (section) -> [IndexPath] in
            var idx = 0
            var results:[IndexPath] = []
            for obj in newObjects {
                let at = idx
                self._list.insert(obj, at: at)
                results.append(IndexPath(row:at,section:section))
                idx += 1
            }
            return results
        }, animated:animated)
    }
    
    /// Remove and return the element at index `i`. Derived class implements.
    public override func delete(_ index: Int, length: Int, animated:Bool? = nil) {
        self.operation(deletes: { (section) -> [IndexPath] in
            if index < 0 || index >= self._list.count {
                return []
            }
            
            let len = self._list.count > (index + length) ? (index + length) : self._list.count
            var results:[IndexPath] = []
            for ii in (index..<len).reversed() {
                self._list.remove(at: ii)
                results.append(IndexPath(row:ii,section:section))
            }
            return results
        }, animated:animated)
    }
    
    
    /// Remove all elements. Derived class implements.
    public override func clear(animated:Bool? = nil) {
        self.operation(deletes: { (section) -> [IndexPath] in
            if self._list.isEmpty {
                return []
            }
            
            var results:[IndexPath] = []
            for ii in (0..<self._list.count).reversed() {
                self._list.remove(at: ii)
                results.append(IndexPath(row:ii,section:section))
            }
            return results
        }, animated:animated)
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

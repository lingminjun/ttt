//
//  LRUCache.swift
//  ttt
//
//  Created by lingminjun on 2018/5/6.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

/**
 @brief LRUCache: Least Recently Used Cache. Thread safe
 */
public struct LRUCache<Key, Value> where Key : Hashable {
    
    /// The element type of a LRUCache: a tuple containing an individual
    /// key-value pair.
    public typealias Element = (key: Key, value: Value)
    
    
    public init(maxCapacity: Int) {
        self._maxCapacity = maxCapacity
    }
    
    public subscript(key: Key) -> Value? {
        mutating get {
            var value:Value? = nil
            synchronized {
                value = _holder[key]
                if value != nil {
                    forthNode(key: key)
                }
            }
            return value
        }
        set {
            synchronized {
                let value = _holder[key]
                if value != nil {
                    forthNode(key: key)
                } else {
                    pushNode(node: Node<Key>(key))
                    if _holder.count == _maxCapacity {
                        if let tail = spillNode() {
                            _holder.removeValue(forKey: tail.key)
                        }
                    }
                }
                _holder[key] = newValue
            }
        }
    }
    
    /// The number of key-value pairs in the LRUCache.
    ///
    /// - Complexity: O(1).
    public var count: Int { get {
        var c = 0
        synchronized { c = _holder.count }
        return c
        }
    }
    
    /// The max capacity of key-value pairs in the LRUCache.
    ///
    /// - Complexity: O(1).
    public var capacity: Int { get { return _maxCapacity } }
    
    /// A Boolean value that indicates whether the LRUCache is empty.
    ///
    /// Dictionaries are empty when created with an initializer or an empty
    /// dictionary literal.
    ///
    ///     var frequencies: [String: Int] = [:]
    ///     print(frequencies.isEmpty)
    ///     // Prints "true"
    public var isEmpty: Bool { get {
        var empty = true
        synchronized { empty = _holder.isEmpty }
        return empty
        }
    }
    
    /// Removes the given key and its associated value from the LRUCache.
    ///
    /// If the key is found in the LRUCache, this method returns the key's
    /// associated value. On removal, this method invalidates all indices with
    /// respect to the LRUCache.
    public mutating func removeValue(forKey key: Key) -> Value? {
        var value:Value? = nil
        synchronized {
            value = _holder.removeValue(forKey: key)
            if value != nil {
                removeNode(key: key)
            }
        }
        return value
    }
    
    /// Removes all key-value pairs from the LRUCache.
    public mutating func removeAll() {
        synchronized {
            _holder.removeAll(keepingCapacity: true)
            _head = nil
        }
    }
    
    /// A collection containing just the keys of the LRUCache.
    public var keys: Dictionary<Key, Value>.Keys { get {
        var ks: Dictionary<Key, Value>.Keys = [:].keys
        synchronized {
            ks = _holder.keys
        }
        return ks
        }
    }
    
    
    private class Node<Key> where Key : Hashable {
        var key:Key
        var next:Node<Key>?
        
        init(_ key:Key) {
            self.key = key
        }
    }
    
    private func findNode(key: Key) -> Node<Key>? {
        var node = _head
        while let n = node {
            if n.key == key {
                return n
            }
            node = n.next
        }
        return nil
    }
    
    private mutating func forthNode(key: Key) {
        //只要一个数据时或者本身是第一个,不要折腾
        if let n = _head, ( n.next == nil || n.key == key ) {
            return
        }
        
        var node = _head
        
        //找到对应位置的前一个
        while let n = node,let next = n.next {
            
            //开始调整
            if next.key == key {
                n.next = next.next //摘除
                next.next = _head  //接在head前面
                _head = next       //放回head
                return
            }
            
            node = n.next
        }
    }
    
    private mutating func pushNode(node: Node<Key>) {
        node.next = _head
        _head = node
    }
    
    //溢出
    @discardableResult
    private mutating func spillNode() -> Node<Key>? {
        //只要一个数据时
        if let n = _head, n.next == nil {
            _head = nil
            return n
        }
        
        var node = _head
        //取倒数第二个
        while let n = node, let next = n.next {
            
            //最后一个了
            if next.next == nil {
                n.next = nil //从链表中摘除
                return next
            }
            
            node = next
        }
        
        return nil
    }
    
    @discardableResult
    private mutating func removeNode(key: Key) -> Node<Key>? {
        //是第一个数据时
        if let n = _head, n.key == key {
            _head = n.next
            n.next = nil
            return n
        }
        
        var node = _head
        
        //找到对应位置的前一个
        while let n = node,let next = n.next {
            
            //开始调整
            if next.key == key {
                n.next = next.next //摘除
                next.next = nil
                return next
            }
            
            node = n.next
        }
        
        return nil
    }
    
    private func synchronized(_ body: () throws -> Void) rethrows {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return try body()
    }
    
    private var _holder:Dictionary<Key, Value> = Dictionary<Key, Value>()
    private var _head:Node<Key>?
    private var _maxCapacity = 0
    
}



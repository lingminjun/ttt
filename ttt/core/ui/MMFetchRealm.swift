//
//  MMFetchRealm.swift
//  merchant-ios
//
//  Created by MJ Ling on 2018/1/8.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation
import RealmSwift
import UIKit

extension RealmSwift.Object : MMCellModel {
    @objc public func ssn_cellID() -> String { return String(describing: type(of: self)) }
    @objc public func ssn_cell(_ cellID : String) -> UITableViewCell { return UITableViewCell(style: .default, reuseIdentifier: cellID)}
    @objc public func ssn_canEdit() -> Bool { return false }
    @objc public func ssn_canMove() -> Bool { return false }
}

public class MMFetchRealm<T: RealmSwift.Object>: MMFetch<T> {
    //使用默认的数据库
    var _list : Results<T>? = nil
    var _notice: NotificationToken? = nil
    lazy var _realm = try! Realm()
    
    override public init(tag:String) {
        super.init(tag: tag)
    }
    
    public init(result: Results<T>, realm: Realm = try! Realm()) {
        super.init(tag:"realm:" + T.className())
        _realm = realm
        _list = result
        
        /*//// :nodoc:
        public func _observe(_ block: @escaping (RealmCollectionChange<AnyRealmCollection<Element>>) -> Void) ->
            NotificationToken {
                let anyCollection = AnyRealmCollection(self)
                return rlmResults.addNotificationBlock { _, change, error in
                    block(RealmCollectionChange.fromObjc(value: anyCollection, change: change, error: error))
                }
        }*/
        _notice?.invalidate()
        _notice = _list?._observe { [weak self] (changes: RealmCollectionChange) in
            guard let delegate = self?._listener else { return }
            switch changes {
            case .initial:
                // tableView.reloadData()
                print("realm result initial...")
                break
            case .update(_, let deletions, let insertions, let modifications):
                delegate.ssn_fetch_begin_change(self!)
                
                //删除者已经拿不到数据
                if deletions.count > 0 {
                    for idx in deletions {
                        delegate.ssn_fetch(self!, didChange: nil, at: idx, for: MMFetchChangeType.delete, newIndex: idx)
                    }
                }
                if insertions.count > 0 {
                    for idx in insertions {
                        let obj = self!._list![idx]
                        delegate.ssn_fetch(self!, didChange: obj, at: idx, for: MMFetchChangeType.insert, newIndex: idx)
                    }
                }
                if modifications.count > 0 {
                    for idx in modifications {
                        let obj = self!._list![idx]
                        delegate.ssn_fetch(self!, didChange: obj, at: idx, for: MMFetchChangeType.update, newIndex: idx)
                    }
                }
                
                delegate.ssn_fetch_end_change(self!)
                break
            case .error(let error):
                print("Error: \(error)")
                break
            }
        }

        
//        _list?._observe({ (<#RealmCollectionChange<AnyRealmCollection<T>>#>) in
//            <#code#>
//        })
    }
    
    /// 
    override public func count() -> Int { return _list!.count }
    override public func objects/*<S: SequenceType where S.Generator.Element: Object>*/() -> [T]? { return Array(_list!)}
    
    /// Update
    override public func update(_ idx: Int, _ b: (() throws -> Void)?) {
        guard let obj = self[idx] else {return}
        do {
            try _realm.write {
                _realm.add(obj, update: true);//(newObjects)
                
                if b != nil {
                    do {
                        try b!()
                    } catch {
                        print("error:\(error)")
                    }
                }
            }
        } catch {
            print("error:\(error)")
        }
    }
    /// Insert `newObject` at index `i`. Derived class implements.
    override public func insert(_ newObjects: [T], atIndex i: Int) {
        do {
            try _realm.write {
                _realm.add(newObjects, update: true);//(newObjects)
            }
        } catch {
            print("error:\(error)")
        }
    }
    
    /// Remove and return the element at index `i`. Derived class implements.
    override public func removeAtIndex(_ index: Int) -> T? {
        if index < 0 || index >= _list!.count {
            return nil
        }
        let obj = _list![index]
        do {
            try _realm.write {
                _realm.delete(obj)
            }
        } catch {
            print("error:\(error)")
        }
        return obj
    }
    override public func removeAtIndex(_ index: Int, length: Int) {
        var objs = [T]()
        for i in (0..<length).reversed() {
            if i + index < _list!.count {
                objs.insert(_list![i + index], at: 0)
            }
        }
        do {
            try _realm.write {
                _realm.delete(objs)
            }
        } catch {
            print("error:\(error)")
        }
    }
    
    /// Remove all elements. Derived class implements.
    override public func removeAll() {
        do {
            try _realm.write {
                _realm.delete(_list!)
            }
        } catch {
            print("error:\(error)")
        }
    }
    
    /// Get element at index. Derived class implements.
    override public func get(_ index: Int) -> T? {
        if index < 0 || index >= _list!.count {
            return nil
        }
        return _list![index]
    }
    
    /// Returns the index of an object in the results collection. Derived class implements.
    override public func indexOf(_ object: T) -> Int? {
        return _list!.index(of: object)
    }
    override public func filter(_ predicate: NSPredicate) -> [T] {
        let rs = _list!.filter(predicate)
        if rs.count <= 0 {
            return []
        }
        return Array(rs)
    }
    
}

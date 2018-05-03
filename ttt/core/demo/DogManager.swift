//
//  DogManager.swift
//  ttt
//
//  Created by lingminjun on 2018/5/3.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import RealmSwift

/**
 * 失败案例，因为realm obj无法穿越线程，否则会异常
 */
class DogManager : Persistence {
    func persistent_queryData(dataId: String) -> FlyModel? {
        let realm = try! Realm()
        let vs = realm.objects(Dog.self).filter("breed='\(dataId)'")
        if vs.count <= 0 {
            return nil
        }
        return vs[0]
    }
    
    func persistent_saveData(dataId: String, model: FlyModel) {
        let realm = try! Realm()
        if let dog = model as? Dog {
            try! realm.write {
                realm.add(dog,update:true)
            }
        }
    }
    
    func persistent_removeData(dataId: String) {
        let realm = try! Realm()
        let vs = realm.objects(Dog.self).filter("breed='\(dataId)'")
        if vs.count <= 0 {
            return
        }
        let dog = vs[0]
        try! realm.write {
            realm.delete(dog)
        }
    }
    
    func persistent_set_notice(notice: Notice) {
        let realm = try! Realm()
        _notice = realm.objects(Dog.self)._observe { [weak self] (changes: RealmCollectionChange) in
            guard let sself = self else { return }
            let _list = realm.objects(Dog.self)
            switch changes {
            case .initial:
                // tableView.reloadData()
                print("realm result initial...")
                break
            case .update(_, let deletions, let insertions, let modifications):
                
                //删除者已经拿不到数据
                if deletions.count > 0 {
                    for idx in deletions {
                        //
                        print("\(idx)")
                    }
                }
                if insertions.count > 0 {
                    for idx in insertions {
                        let obj = _list[idx]
                        notice.on_data_update(model: obj, isDeleted: false)
                    }
                }
                if modifications.count > 0 {
                    for idx in modifications {
                        let obj = _list[idx]
                        notice.on_data_update(model: obj, isDeleted: false)
                    }
                }
                
                break
            case .error(let error):
                print("Error: \(error)")
                break
            }
        }
    }
    
    open static let shared = DogManager()
    public var fly:Flyweight<Dog>!
//    private var realm:Realm!
    var _notice: NotificationToken? = nil
//    var _list : Results<Dog>!
    
    init() {
        
        let TIMES = UserDefaults.standard.integer(forKey: ".app.start.times")
//        _list = realm.objects(Dog.self)
        fly = Flyweight<Dog>.init(capacity: 100, psstn: self, flag: Int64(TIMES))
        
        
    }
    
    deinit {
        _notice?.invalidate()
        _notice = nil
    }
}

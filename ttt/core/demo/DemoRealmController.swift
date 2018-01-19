//
//  DemoRealmController.swift
//  ttt
//
//  Created by lingminjun on 2018/1/13.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import UIKit
import RealmSwift

// ------------------------------------------------------------------------
// tableView的基本
class DemoRealmController: MMUITableController<Dog> {
    
    override func loadFetchs() -> [MMFetch<Dog>] {
        //使用默认的数据库
        let realm = try! Realm()
        let vs = realm.objects(Dog.self).sorted(byKeyPath: "breed", ascending: false)
        let f = MMFetchRealm(result:vs,realm:realm)
        return [f]
    }
    

    
    // MARK:- UITableViewDelegate代理
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("点击了\(indexPath.row)")
        tableView.deselectRow(at: indexPath, animated: false)
        self.ssn_back()
    }
}


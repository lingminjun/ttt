//
//  FetchRLMResults.swift
//  merchant-ios
//
//  Created by MJ Ling on 2018/1/2.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation
import RealmSwift

public class MMFetchRLMResults<T: Object> {
    
    var _realm : Realm!
    var _list : Results<T>?
    var _notice : NotificationToken?
    
//    convenience init(realm : Realm = try! Realm()) {
//        var xx = ["aa","dd"];
//        xx.append("xx");
//        xx.insert("dd", atIndex: 0);
//    }
    
//    convenience init(realm : Realm = try! Realm(), filter : NSPredicate, sorts: [SortDescriptor]) {
//        self.init()
//        _realm = realm;
//        _list = _realm.objects(T).filter(filter)
//        
//        //添加排序
//        if sorts.count > 0 {
//            _list?.sorted(sorts)
//        }
//        
//        _notice?.stop()
//        _notice = _list?.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
//            guard let tableView = self?.tableView else { return }
//            switch changes {
//            case .initial:
//                tableView.reloadData()
//                break
//            case .update(_, let deletions, let insertions, let modifications):
//                tableView.beginUpdates()
//
//                tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
//                
//                tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
//                tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
//                tableView.endUpdates()
//                break
//            case .error(let error):
//                print("Error: \(error)")
//                break
//            }
//        }
//
//        
//    }
//    
//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return sectionNames.count
//    }
//    
//    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return sectionNames[section]
//    }
//    
//    override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
//        return items.filter("race == %@", sectionNames[section]).count
//    }
//    
//    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
//        cell.textLabel?.text = items.filter("race == %@", sectionNames[indexPath.section])[indexPath.row].name
//        return cell
//    }
    
//    MMFetchRLMResults(realm : Realm = Realm(), objClass : Class, filter : NSPredicate, sorted: String) {
//
////    Realm().objects(
//    }
}

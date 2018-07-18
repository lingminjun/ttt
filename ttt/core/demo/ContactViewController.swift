//
//  ContactViewController.swift
//  ttt
//
//  Created by lingminjun on 2018/7/9.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import HandyJSON

class Person: NSObject, SQLiteModel {
    var ssn_rowid: Int64 = -1
    
    func ssn_cellID() -> String {
        return "Person"
    }
    
    func ssn_groupID() -> String? {
        return nil
    }
    
    func ssn_canEdit() -> Bool {
        return false
    }
    
    func ssn_canMove() -> Bool {
        return false
    }
    
    func ssn_cellHeight() -> CGFloat {
        return 44
    }
    
    func ssn_cellInsets() -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func ssn_canFloating() -> Bool {
        return false
    }
    
    func ssn_isExclusiveLine() -> Bool {
        return false
    }
    
    func ssn_cellGridSpanSize() -> Int {
        return 0
    }
    
    override required init() {
        //
    }
    
    func ssn_cell(_ cellID : String) -> UITableViewCell {
        return PersonCell.init(style: UITableViewCellStyle.default, reuseIdentifier: cellID)
    }
    
    var uid = 0
    var name = ""
    var age = 0
    var sex = 0
    var birth = ""
}

class PersonCell: UITableViewCell {
    override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject, atIndexPath indexPath: IndexPath, reused: Bool) {
        if let person = model as? Person {
            self.textLabel?.text = "\(person.name) age:\(person.age) birth:\(person.birth)"
            print("uid:\(person.uid) age:\(person.age) birth:\(person.birth)")
        }
    }
}

class ContactViewController: MMUITableController<Person> {
    
    var sbtable:DBTable!
    
    override func loadFetchs() -> [MMFetch<Person>] {
        let query = SQLQuery<Person>(table: "person", specified:("uid",[
            60,61,62,63,64,65,66,67,68,69,
            70,71,72,73,74,75,76,77,78,79]), sort:"name")
        let db = DB.db(with: "default")
        let f = MMFetchSQLite(query: query, db: db)
        return [f]
    }
    
    override func onViewDidLoad() {
        super.onViewDidLoad()
        let db = DB.db(with: "default")
        sbtable = DBTable.table(db: db, name: "person")
        let sel = #selector(ContactViewController.rightAction)
        let item = UIBarButtonItem(title: "添加", style: UIBarButtonItemStyle.plain, target: self, action: sel)
        self.navigationItem.rightBarButtonItem=item
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row > 5 {
            if let obj = self.fetchs.fetch.get(indexPath.row) {
                obj.age = obj.age + 1
                self.sbtable.update(object: obj)
            }
        } else {
            if let obj = self.fetchs.fetch.get(indexPath.row) {
                self.sbtable.delete(object: obj)
            }
        }
    }
    
    @objc func rightAction() -> Void {
        let ps = Person()
        ps.name = "测试\(arc4random())"
        ps.age = Int(arc4random()%30)
        ps.sex = Int(arc4random()%2)
        sbtable.insert(object: ps)
    }
    
}

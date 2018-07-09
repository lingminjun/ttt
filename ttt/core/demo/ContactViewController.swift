//
//  ContactViewController.swift
//  ttt
//
//  Created by lingminjun on 2018/7/9.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import HandyJSON

class Person: NSObject, MMCellModel, HandyJSON {
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
}

class PersonCell: UITableViewCell {
    override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject, atIndexPath indexPath: IndexPath, reused: Bool) {
        if let person = model as? Person {
            self.textLabel?.text = person.name
        }
    }
}

class ContactViewController: MMUITableController<Person> {
    
    override func loadFetchs() -> [MMFetch<Person>] {
        let f = MMFetchList<Person>(list:[])
        return [f]
    }
    
    override func onViewDidLoad() {
        let sel = #selector(ContactViewController.rightAction)
        let item = UIBarButtonItem(title: "选项", style: UIBarButtonItemStyle.plain, target: self, action: sel)
        self.navigationItem.rightBarButtonItem=item
    }
    
    @objc func rightAction() -> Void {
        let db = DB.db(with: "default")
        let table = DBTable.table(db: db, name: "person")
        
        let ps = Person()
        ps.name = "测试\(arc4random())"
        ps.age = Int(arc4random()%30)
        ps.sex = Int(arc4random()%2)
        table.insert(object: ps)
    }
    
}

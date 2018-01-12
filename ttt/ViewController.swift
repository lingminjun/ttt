//
//  ViewController.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/12.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import UIKit

import RealmSwift

extension Dog {
    @objc public override func ssn_cellID() -> String {return "dog"}
    @objc public override func ssn_cell(_ cellID : String) -> UITableViewCell {
        return DogCell(style: .default, reuseIdentifier: cellID)
    }
    @objc public override func ssn_canEdit() -> Bool {return false}
    @objc public override func ssn_canMove() -> Bool {return false}
}

class ViewController: MMUIController {
    
    // 注意: Swift中mark注释的格式: MARK:-
    // MARK:- 属性
    let cellID = "cell"
    var _table : UITableView!
    
    var _fetch : MMFetchsController<Dog>?
    
    override func onViewDidLoad() {
        super.viewDidLoad()
        
        //初始化数据是否准备
        let realm = try! Realm()
        let vs = realm.objects(Dog.self)
        if vs.count == 0 {
            if true {
                let d = Dog()
                d.breed = "藏獒"
                d.brains = 60
                d.loyalty = 90
                d.name = "藏獒"
                try! realm.write {
                realm.add(d)
                }
            }
            
            if true {
                let d = Dog()
                d.breed = "中华田园犬"
                d.brains = 80
                d.loyalty = 80
                d.name = "土狗"
                try! realm.write {
                realm.add(d)
                }
            }
            
            if true {
                let d = Dog()
                d.breed = "拉布拉多"
                d.brains = 110
                d.loyalty = 90
                d.name = "拉布拉多"
                try! realm.write {
                realm.add(d)
                }
            }
        }
 
        
        // 1.创建tableView,并添加的控制器的view
        let tableView = UITableView(frame: view.bounds)
        
        // 2.设置数据源代理
//        tableView.dataSource = self
        tableView.delegate = self
        
        // 3.添加到控制器的view
        view.addSubview(tableView)
        _table = tableView
        
        // 4.注册cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        
        //使用默认的数据库
        var f = MMFetchRealm(result:vs,realm:realm)
        _fetch = MMFetchsController(fetchs:[f])
//        _fetch?.delegate = self
        tableView.dataSource = _fetch
//        let predicate = NSPredicate(format: "type.name = '购物' AND cost > 10")
        //        consumeItems = realm.objects(ConsumeItem.self).filter(predicate)
    }

    override func onReceiveMemoryWarning() {
        super.onReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

// ------------------------------------------------------------------------
// Swift中类的扩展: Swift中的扩展相当于OC中的分类
extension ViewController: MMFetchsControllerDelegate, UITableViewDelegate {
    func ssn_controller(_ controller: AnyObject, didChange anObject: MMCellModel, at indexPath: IndexPath?, for type: MMFetchChangeType, newIndexPath: IndexPath?) {
        //
    }
    
    func ssn_controllerWillChangeContent(_ controller: AnyObject) {
        //
    }
    
    func ssn_controllerDidChangeContent(_ controller: AnyObject) {
        //
    }

    
    
    // MARK:- UITableViewDelegate代理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("点击了\(indexPath.row)")
    }
}


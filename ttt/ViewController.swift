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
        return DogCell(style: .subtitle, reuseIdentifier: cellID)
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
        
        self.title = "首页"
        
        //初始化数据是否准备
        let realm = try! Realm()
        let vs = realm.objects(Dog.self)
        if vs.count == 0 {
            initializationData(realm: realm)
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
        let ff = vs.sorted(byKeyPath: "breed", ascending: true)
        var f = MMFetchRealm(result:ff,realm:realm)
        _fetch = MMFetchsController(fetchs:[f])
        _fetch?.delegate = self
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
    func ssn_controller(_ controller: AnyObject, didChange anObject: MMCellModel?, at indexPath: IndexPath?, for type: MMFetchChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            _table.deleteRows(at: [indexPath!], with: .automatic)
        case .insert:
            _table.insertRows(at: [indexPath!], with: .automatic)
        case .update:
            _table.reloadRows(at: [indexPath!], with: .automatic)
        default:
            _table.deleteRows(at: [indexPath!], with: .automatic)
            _table.insertRows(at: [newIndexPath!], with: .automatic)
        }
    }
    
    func ssn_controllerWillChangeContent(_ controller: AnyObject) {
        _table.beginUpdates()
    }
    
    func ssn_controllerDidChangeContent(_ controller: AnyObject) {
        _table.endUpdates()    }

    
    
    // MARK:- UITableViewDelegate代理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("点击了\(indexPath.row)")
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.row == 0 {
            _fetch?[0]?.delete(0);
        } else if (indexPath.row == 1) {
            insertOrUpdate(fetch: (_fetch?[0]!)!, idx: indexPath.row)
        } else if (indexPath.row == 2) {
            orderThreadInsert()
        } else if (indexPath.row == 5) {
            _fetch?.delete(at: indexPath)
        } else if (indexPath.row == 6) {
            let d = Dog()
            d.breed = "法国比利牛斯指示犬"
            d.brains = 60
            d.loyalty = 90
            d.name = "法国比利牛斯指示犬"
            _fetch?.insert(obj: d, at: indexPath)
        } else if (indexPath.row == 7) {
            let vc = DemoListController()
//            self.present(vc, animated: true, completion: nil)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        else {
            let dog = _fetch?.object(at: indexPath)
            _fetch?.update(at: indexPath, {
                dog?.brains += 1;
            })
        }
    }
}

/// test dataing
extension ViewController {
    func initializationData(realm: Realm) {
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
    
    
    func insertOrUpdate(fetch: MMFetch<Dog>, idx:Int) {
        if true {
            let d = Dog()
            d.breed = "泰迪犬"
            d.brains = 60
            d.loyalty = 90
            d.name = "泰迪犬"
            fetch.insert(d, atIndex: idx)
        }
        if true {
            let d = Dog()
            d.breed = "博美犬"
            d.brains = 60
            d.loyalty = 90
            d.name = "博美犬"
            fetch.insert(d, atIndex: idx)
        }
    }
    func xxxx() throws {
        let realm = try! Realm()
        
        if true {
            let d = Dog()
            d.breed = "金毛"
            d.brains = 60
            d.loyalty = 90
            d.name = "金毛"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
        if true {
            let d = Dog()
            d.breed = "萨摩耶"
            d.brains = 60
            d.loyalty = 90
            d.name = "萨摩耶"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
        if true {
            let d = Dog()
            d.breed = "比熊"
            d.brains = 60
            d.loyalty = 90
            d.name = "比熊"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
        if true {
            let d = Dog()
            d.breed = "哈士奇"
            d.brains = 60
            d.loyalty = 90
            d.name = "哈士奇"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
        if true {
            let d = Dog()
            d.breed = "阿拉斯加雪橇犬"
            d.brains = 60
            d.loyalty = 90
            d.name = "阿拉斯加雪橇犬"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
        if true {
            let d = Dog()
            d.breed = "拉布拉多"
            d.brains = 60
            d.loyalty = 90
            d.name = "拉布拉多"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
        if true {
            let d = Dog()
            d.breed = "德国牧羊犬"
            d.brains = 60
            d.loyalty = 90
            d.name = "德国牧羊犬"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
        if true {
            let d = Dog()
            d.breed = "松狮"
            d.brains = 60
            d.loyalty = 90
            d.name = "松狮"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
        if true {
            let d = Dog()
            d.breed = "吉娃娃"
            d.brains = 60
            d.loyalty = 90
            d.name = "吉娃娃"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
        if true {
            let d = Dog()
            d.breed = "标准贵宾"
            d.brains = 60
            d.loyalty = 90
            d.name = "标准贵宾"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
        if true {
            let d = Dog()
            d.breed = "约克夏"
            d.brains = 60
            d.loyalty = 90
            d.name = "约克夏"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
        if true {
            let d = Dog()
            d.breed = "高加索牧羊犬"
            d.brains = 60
            d.loyalty = 90
            d.name = "高加索牧羊犬"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
        if true {
            let d = Dog()
            d.breed = "雪纳瑞"
            d.brains = 60
            d.loyalty = 90
            d.name = "雪纳瑞"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
        if true {
            let d = Dog()
            d.breed = "古牧"
            d.brains = 60
            d.loyalty = 90
            d.name = "古牧"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
        if true {
            let d = Dog()
            d.breed = "巴哥"
            d.brains = 60
            d.loyalty = 90
            d.name = "巴哥"
            try! realm.write {
                realm.add(d,update:true)
            }
        }
    }
    func orderThreadInsert() {
        let queue = DispatchQueue(label: "com.geselle.demoQueue")
        queue.async { [weak self] () -> () in
            try! self?.xxxx()
        }
    }
}


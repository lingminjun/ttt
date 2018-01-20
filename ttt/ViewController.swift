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

class ViewController: MMUITableController<Dog> {
    
    public override func loadFetchs() -> [MMFetch<Dog>] {
        let realm = try! Realm()
        let vs = realm.objects(Dog.self)
        if vs.count == 0 {
            initializationData(realm: realm)
        }
        let ff = vs.sorted(byKeyPath: "breed", ascending: true)
        let f = MMFetchRealm(result:ff,realm:realm)
        return [f]
    }
    
    public override func onViewDidLoad() {
        super.onViewDidLoad()
        
        let sel = #selector(ViewController.rightAction)
        //title: String?, style: UIBarButtonItemStyle, target: Any?, action: Selector?
        let item = UIBarButtonItem(title: "百度", style: UIBarButtonItemStyle.plain, target: self, action: sel)
        self.navigationItem.rightBarButtonItem=item
    }
    
    @objc func rightAction() -> Void {
        Navigator.shared.open("https://m.baidu.com?_on_browser")
    }
    
    override func onReceiveMemoryWarning() {
        super.onReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK:- UITableViewDelegate代理
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("点击了\(indexPath.row)")
        tableView.deselectRow(at: indexPath, animated: false)
        if indexPath.row == 0 {
            self.fetchs[0]?.delete(0);
        } else if (indexPath.row == 1) {
            insertOrUpdate(fetch: (self.fetchs[0]!), idx: indexPath.row)
        } else if (indexPath.row == 2) {
            orderThreadInsert()
        } else if (indexPath.row == 5) {
            self.fetchs.delete(at: indexPath)
        } else if (indexPath.row == 6) {
            let d = Dog()
            d.breed = "法国比利牛斯指示犬"
            d.brains = 60
            d.loyalty = 90
            d.name = "法国比利牛斯指示犬"
            self.fetchs.insert(obj: d, at: indexPath)
        } else if (indexPath.row == 7) {
            Navigator.shared.open("https://m.mymm.com/setting.html")
//            let vc = DemoListController()
//            self.navigationController?.pushViewController(vc, animated: true)
        } else if (indexPath.row == 8) {
//            let params = ["_load_url":Urls.QValue("https://m.baidu.com")]
            let params = ["_load_url":Urls.QValue("https://m.fengqu.com")]
            Navigator.shared.open("https://m.mymm.com/web.html",params:params)
        } else if (indexPath.row == 9) {
            self.fetchs.delete(at: indexPath)
        }
        else {
            let dog = self.fetchs.object(at: indexPath)
            self.fetchs.update(at: indexPath, {
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


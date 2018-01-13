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
class DemoRealmController: MMUIController {
    
    // 注意: Swift中mark注释的格式: MARK:-
    // MARK:- 属性
    let cellID = "cell"
    var _table : UITableView!
    var _fetch : MMFetchsController<Dog>?
    
    override func onViewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Realm列表"
        
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
        let realm = try! Realm()
        let vs = realm.objects(Dog.self).sorted(byKeyPath: "breed", ascending: false)
        var f = MMFetchRealm(result:vs,realm:realm)
        _fetch = MMFetchsController(fetchs:[f])
        _fetch?.delegate = self
        tableView.dataSource = _fetch
    }
    
    
}

// ------------------------------------------------------------------------
// Swift中类的扩展: Swift中的扩展相当于OC中的分类
extension DemoRealmController: MMFetchsControllerDelegate,UITableViewDelegate {
    
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
        _table.endUpdates()
    }
    
    
    // MARK:- UITableViewDelegate代理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("点击了\(indexPath.row)")
        if indexPath.row == 0 {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

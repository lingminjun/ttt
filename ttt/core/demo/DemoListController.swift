//
//  DemoListController.swift
//  merchant-ios
//
//  Created by MJ Ling on 2018/1/2.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import RealmSwift

// ------------------------------------------------------------------------
// tableView的基本
class DemoListController: MMUIController {
    
    // 注意: Swift中mark注释的格式: MARK:-
    // MARK:- 属性
    let cellID = "cell"
    var _table : UITableView!
    
    override func onViewDidLoad() {
        super.viewDidLoad()
        
        // 1.创建tableView,并添加的控制器的view
        let tableView = UITableView(frame: view.bounds)
        
        // 2.设置数据源代理
        tableView.dataSource = self
        tableView.delegate = self
        
        // 3.添加到控制器的view
        view.addSubview(tableView)
        _table = tableView
        
        // 4.注册cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        
        //使用默认的数据库
        let realm = try! Realm()
        let predicate = NSPredicate(format: "type.name = '购物' AND cost > 10")
//        consumeItems = realm.objects(ConsumeItem.self).filter(predicate)
    }
    
    
}

// ------------------------------------------------------------------------
// Swift中类的扩展: Swift中的扩展相当于OC中的分类
extension DemoListController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    // MARK:- UITableViewDataSource数据源
    // 必须实现UITableViewDataSource的option修饰的必须实现的方法,否则会报错
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        /*
         // ----------------------------------------------------------------
         // 使用普通方式创建cell
         let cellID = "cell"
         
         // 1.创建cell,此时cell是可选类型
         var cell = tableView.dequeueReusableCellWithIdentifier(cellID)
         
         // 2.判断cell是否为nil
         if cell == nil {
         cell = UITableViewCell(style: .Default, reuseIdentifier: cellID)
         }
         
         // 3.设置cell数据
         cell?.textLabel?.text = "测试数据\(indexPath.row)"
         
         return cell!
         */
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID)
        
        cell?.textLabel?.text = "测试数据\(indexPath.row)"
        
        return cell!
        
    }
    
    // MARK:- UITableViewDelegate代理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("点击了\(indexPath.row)")
    }
}


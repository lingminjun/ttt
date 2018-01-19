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
    var _fetch : MMFetchsController<SettingNode>?
    
    func initDataList() -> [SettingNode] {
        var list = [] as [SettingNode]
        if true {
            var node = SettingNode()
            node.title = "随意设计1"
            node.subTitle = "new"
            list.insert(node, at: 0)
        }
        if true {
            var node = SettingNode()
            node.title = "随意设计2"
            node.subTitle = "new"
            list.append(node)
        }
        if true {
            var node = SettingNode()
            node.title = "随意设计3"
            node.subTitle = "new"
            list.append(node)
        }
        if true {
            var node = SettingNode()
            node.title = "随意设计4"
            node.subTitle = "new"
            list.append(node)
        }
        return list
    }
    
    override func onViewDidLoad() {
        super.viewDidLoad()
        
        self.title = "List列表"
        
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
        var f = MMFetchList(list:initDataList())
        _fetch = MMFetchsController(fetchs:[f])
        _fetch?.delegate = self
        tableView.dataSource = _fetch
    }
    
    
}

// ------------------------------------------------------------------------
// Swift中类的扩展: Swift中的扩展相当于OC中的分类
extension DemoListController: MMFetchsControllerDelegate,UITableViewDelegate {
    
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
//            self.dismiss(animated: true, completion: nil)
//            self.navigationController?.popViewController(animated: true)
            self.ssn_back()
        } else if indexPath.row == 1 {
            var node = SettingNode()
            node.title = "插入数据1"
            node.subTitle = "new"
            _fetch?.insert(obj: node, at: indexPath)
        } else if indexPath.row == 2 {
            var list = [SettingNode]()
            if true {
                var node = SettingNode()
                node.title = "插入连续1"
                node.subTitle = "new"
                list.append(node)
            }
            if true {
                var node = SettingNode()
                node.title = "插入连续2"
                node.subTitle = "new"
                list.append(node)
            }
            if true {
                var node = SettingNode()
                node.title = "插入连续3"
                node.subTitle = "new"
                list.append(node)
            }
            _fetch?[indexPath.section]?.insert(list, atIndex: indexPath.row)
        } else if indexPath.row == 3 {
            let node = _fetch?.object(at: indexPath)
            node?.subTitle = "修改"
            _fetch?.update(at: indexPath, nil)
        } else if indexPath.row == 4 {
            Navigator.shared.open("https://m.mymm.com/dog/list.html")
        } else {
            _fetch?.delete(at: indexPath)
        }
    }
}


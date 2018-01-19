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
class DemoListController: MMUITableController<SettingNode> {
    
    override func loadFetchs() -> [MMFetch<SettingNode>] {
        //使用默认的数据库
        var f = MMFetchList(list:initDataList())
        return [f]
    }
    
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
    
    // MARK:- UITableViewDelegate代理
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("点击了\(indexPath.row)")
        if indexPath.row == 0 {
            //            self.dismiss(animated: true, completion: nil)
            //            self.navigationController?.popViewController(animated: true)
            self.ssn_back()
        } else if indexPath.row == 1 {
            var node = SettingNode()
            node.title = "插入数据1"
            node.subTitle = "new"
            self.fetchs.insert(obj: node, at: indexPath)
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
            self.fetchs[indexPath.section]?.insert(list, atIndex: indexPath.row)
        } else if indexPath.row == 3 {
            let node = self.fetchs.object(at: indexPath)
            node?.subTitle = "修改"
            self.fetchs.update(at: indexPath, nil)
        } else if indexPath.row == 4 {
            Navigator.shared.open("https://m.mymm.com/dog/list.html")
        } else {
            self.fetchs.delete(at: indexPath)
        }
    }
    
}

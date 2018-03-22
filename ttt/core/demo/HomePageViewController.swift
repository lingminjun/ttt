//
//  HomePageViewController.swift
//  MMDemoForLeslie_Swift4.0
//
//  Created by Leslie Zhang on 2018/3/22.
//  Copyright © 2018年 Leslie Zhang. All rights reserved.
//

import UIKit

class HomePageViewController:MMUICollectionController<SettingNode> {
    
    convenience init(_ str:String) {
    self.init(nibName: nil, bundle: nil)
    }
    
    override func loadFetchs() -> [MMFetch<SettingNode>] {
        let list = [] as [SettingNode]
        let f = MMFetchList(list:list)
        return [f]
    }
    
    override func onViewDidLoad() {
        super.onViewDidLoad()
//        DispatchQueue.main.async {
            self.initDataList()
//        }
        
//        initDataList()
//       self.fetchs.fetch.append(initDataList())
        
    }
    
    
    func initDataList() -> [SettingNode] {
    var list = [] as [SettingNode]
    
    for i in 0..<50 {
    let node = SettingNode()
    node.title = "数据\(i)"
    if i == 0{
    node.isExclusiveLine = true
    node.cellHeight = 100
    }else{
    node.isExclusiveLine = false
    node.cellHeight = 22
    }
    
    list.insert(node, at: i)
       self.fetchs.fetch.append(node)
    }
    
    return list
    }
    
    override func loadLayoutConfig() -> MMLayoutConfig {
    var _config:MMLayoutConfig = MMLayoutConfig()
    _config.rowHeight = 0
    _config.columnCount = 2
    return _config
    }

}

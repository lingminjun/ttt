//
//  DemoCollectionController.swift
//  ttt
//
//  Created by lingminjun on 2018/5/21.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

class NormalNode : NSObject,MMCellModel {
    func ssn_groupID() -> String? {
        return nil
    }
    
    func ssn_cellInsets() -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func ssn_cellGridSpanSize() -> Int {
        return 1
    }
    
    func ssn_cellHeight() -> CGFloat {
        return cellHeight
    }
    
    func ssn_canFloating() -> Bool {
        return false
    }
    
    func ssn_isExclusiveLine() -> Bool {
        return isExclusiveLine
    }
    
    func ssn_cellID() -> String {
        return String(describing: type(of: self))
    }
    
    func ssn_canEdit() -> Bool {
        return false
    }
    
    func ssn_canMove() -> Bool {
        return false
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return NormalCell.self
    }
    
    public var title: String = ""
    public var subTitle: String = ""
    public var isExclusiveLine: Bool = false
    public var cellHeight:CGFloat = 44.0
}

class NormalCell: UICollectionViewCell {
    
    var textLabel:UILabel? = nil
    var detailTextLabel:UILabel? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        textLabel = UILabel.init(frame: self.bounds)
        self.addSubview(textLabel!)
        self.backgroundColor = UIColor.white
    }
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        textLabel = UILabel.init(frame: self.bounds)
        self.addSubview(textLabel!)
        self.backgroundColor = UIColor.white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        self.textLabel?.text = ""
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused:Bool) {
        if let node: NormalNode = model as? NormalNode {
            self.textLabel?.text = node.title
        }
    }
}

class HeadNode : NSObject,MMCellModel {
    func ssn_groupID() -> String? {
        return nil
    }
    
    func ssn_cellInsets() -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func ssn_cellGridSpanSize() -> Int {
        return 1
    }
    
    func ssn_cellHeight() -> CGFloat {
        return cellHeight
    }
    
    func ssn_canFloating() -> Bool {
        return true
    }
    
    func ssn_isExclusiveLine() -> Bool {
        return isExclusiveLine
    }
    
    func ssn_cellID() -> String {
        return String(describing: type(of: self))
    }
    
    func ssn_canEdit() -> Bool {
        return false
    }
    
    func ssn_canMove() -> Bool {
        return false
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        if isFloating {
            return HeadCell.self
        } else {
            return NormalCell.self
        }
        
    }
    
    public var title: String = ""
    public var subTitle: String = ""
    public var isExclusiveLine: Bool = false
    public var cellHeight:CGFloat = 30
}

class HeadCell: UICollectionReusableView {
    
    var textLabel:UILabel? = nil
    var detailTextLabel:UILabel? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        textLabel = UILabel.init(frame: self.bounds)
        self.addSubview(textLabel!)
        self.backgroundColor = UIColor.yellow
    }
    
    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 320, height: 30))
        textLabel = UILabel.init(frame: self.bounds)
        self.addSubview(textLabel!)
        self.backgroundColor = UIColor.yellow
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        self.textLabel?.text = ""
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused:Bool) {
        if let node: HeadNode = model as? HeadNode {
            self.textLabel?.text = node.title
        }
    }
}


class DemoCollectionController : MMUICollectionController<MMCellModel> {
    
    override func loadLayoutConfig() -> MMLayoutConfig {
        var config = MMLayoutConfig()
        config.floating = true
        return config
    }
    
    //
    override func loadFetchs() -> [MMFetch<MMCellModel>] {
        
        ///构建测试数据
        var list:[MMCellModel] = []
        
        for idx in 1...3 {
            
            let node = HeadNode()
            node.title = "title\(idx)"
            list.append(node)
            
            
            for i in 0..<7 {
                let node = NormalNode()
                node.title = "title\(idx) 下的数据 \(i)"
                list.append(node)
            }
        }
         
         ///
         let f = MMFetchList(list:list)
 
         return [f]
 
    }
}
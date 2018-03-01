//
//  SettingV1Cell.swift
//  ttt
//
//  Created by lingminjun on 2018/1/13.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit

class SettingV1Cell: UICollectionViewCell {
    
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
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath) {
        let node: SettingNode = model as! SettingNode
        self.textLabel?.text = node.title
//        self.detailTextLabel?.text = node.subTitle
    }
}

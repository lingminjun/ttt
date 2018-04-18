//
//  SettingCell.swift
//  ttt
//
//  Created by lingminjun on 2018/1/13.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit

class SettingCell: UITableViewCell {
    override func prepareForReuse() {
        self.textLabel?.text = ""
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused:Bool) {
        let node: SettingNode = model as! SettingNode
        self.textLabel?.text = node.title
        self.detailTextLabel?.text = node.subTitle
    }
}

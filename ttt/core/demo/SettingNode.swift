//
//  SettingNode.swift
//  ttt
//
//  Created by lingminjun on 2018/1/13.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit

class SettingNode : NSObject,MMCellModel {
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
    
    func ssn_cell(_ cellID: String) -> UITableViewCell {
        return SettingCell(style: .value1, reuseIdentifier: cellID)
    }
    
    func ssn_canEdit() -> Bool {
        return false
    }
    
    func ssn_canMove() -> Bool {
        return false
    }
    
    func ssn_cellClass(_ cellID: String, isFloating: Bool) -> AnyClass {
        return SettingV1Cell.self
    }
    
    public var title: String = ""
    public var subTitle: String = ""
    public var isExclusiveLine: Bool = false
    public var cellHeight:CGFloat = 44.0
}

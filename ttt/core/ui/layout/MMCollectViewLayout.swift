//
//  MMCollectViewLayout.swift
//  ttt
//
//  Created by lingminjun on 2018/2/27.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import UIKit
import Foundation

class MMCollectViewLayout: UICollectionViewLayout {
    var floating:Bool = false//存在某些cell飘浮，此选项开启，会造成性能损耗
    var columnCount = 1
    var columnSpace:UInt = 10//(dp)
    var rowDefaultSpace:UInt = 10;//默认行间距(dp)
    var insest:UIEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10);
}

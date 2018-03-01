//
//  DogCell.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/12.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit

class DogCell: UITableViewCell {
    override func prepareForReuse() {
        self.textLabel?.text = ""
    }
    
    @objc override func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath) {
        let dog: Dog = model as! Dog
        self.textLabel?.text = dog.breed
        self.detailTextLabel?.text = "智力：\(dog.brains)"
    }
}

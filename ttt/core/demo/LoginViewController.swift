//
//  LoginViewController.swift
//  ttt
//
//  Created by lingminjun on 2018/2/14.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit
import RealmSwift

class LoginViewController: MMUIController {
    public override func onViewDidLoad() {
        super.onViewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        let sel = #selector(ViewController.rightAction)
        //title: String?, style: UIBarButtonItemStyle, target: Any?, action: Selector?
        let item = UIBarButtonItem(title: "关闭", style: UIBarButtonItemStyle.plain, target: self, action: sel)
        self.navigationItem.rightBarButtonItem=item
    }
    
    @objc func rightAction() -> Void {
        (UIApplication.shared.delegate! as! AppDelegate).auth = true
        self.ssn_back()
    }
}

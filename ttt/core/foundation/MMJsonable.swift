//
//  MMJsonable.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/17.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

//json convert
public protocol MMJsonable {
    func ssn_jsonString() -> String
    static func ssn_from(json:String) -> Self?
}

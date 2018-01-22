//
//  RPC.swift
//  ttt
//
//  Created by lingminjun on 2018/1/21.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation


public final class RPC {
    public enum Callback {
        case start(tag:String)
        case finish(tag:String)
        case failed(tag:String, error: NSError)
        case staged(tag:String, obj: AnyObject) //Stage success.
    }
    
    public static func call(callback:Callback) {
        
    }
}

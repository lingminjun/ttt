//
//  DogManager.swift
//  ttt
//
//  Created by lingminjun on 2018/5/3.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

/**
 * 失败案例，因为realm obj无法穿越线程，否则会异常
 */
class DogManager  {
    
    open static let shared = DogManager()
    
    public var fly:Flyweight<Dog>!
    
    init() {
        
        let TIMES = UserDefaults.standard.integer(forKey: ".app.start.times")
//        _list = realm.objects(Dog.self)
        fly = Flyweight<Dog>(capacity: 3, storeScope:"dog", flag: Int64(TIMES))
    }
    
}

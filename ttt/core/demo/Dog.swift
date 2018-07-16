//
//  Dog.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/12.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import RealmSwift
import HandyJSON


///http://www.ganji.com/dog/
public final class Dog : RealmSwift.Object,MMJsonable,Codable,FlyModel,HandyJSON {
    public var data_unique_id: String {
        get { return breed }
    }
    
    public var data_sync_flag: Int64 {
        get { return flag }
        set { flag = newValue }
    }
    
    public func ssn_jsonString() -> String {
        let js = JSONEncoder()
        if let data = try? js.encode(self),let str = String(data: data, encoding: String.Encoding.utf8) {
            return str
        }
        return "{\"breed\":\"\(breed)\",\"name\":\"\(name)\",\"brains\":\"\(brains)\",\"loyalty\":\"\(loyalty)\"}"
    }
    
    
    public static func ssn_from(json: String) -> Dog? {
        let js = JSONDecoder()
        let dog = try? js.decode(self, from: json.data(using: String.Encoding.utf8)!)
        return dog
    }
    
    @objc public dynamic var breed: String = "中华田园犬"
    @objc public dynamic var name: String = ""
    @objc public dynamic var brains: Int = 80 // MAX = 120
    @objc public dynamic var loyalty: Int = 80
    @objc public dynamic var flag: Int64 = 0
    
    //https://www.jianshu.com/p/fef63f4cf6b4
    @objc override static open func primaryKey() -> String? { return "breed" }
}




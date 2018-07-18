//
//  Injects.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/15.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import HandyJSON

/// reflect //http://www.hangge.com/blog/cache/detail_976.html
final public class Injects {
    
    /// Get the property value
    open static func get(property: String,of obj: HandyJSON) -> Any? {
        
        if let dic = obj.toJSON() {
            return dic[property]
        }
        
        return nil
    }
    
    /// Is a Type, similar to Swift.Type (of:)
    open static func isType(_ obj: Any, type: Any.Type) -> Bool {
//        return (obj as? type) != nil
        
        let t = Swift.type(of: obj)
        if t == type {
            return true
        }
        
        // recursive
        var mr: Mirror = Mirror(reflecting: obj)
        while let parent = mr.superclassMirror {
            if parent.subjectType == type {
                return true
            }
            mr = parent
        }
        return false
    }
    
    /// contained Int,Float,Double,Bool,Character,String
    open static func isBaseType(_ obj: Any) -> Bool {
//        let type = Swift.type(of: obj)
        
        if obj is Int
            || obj is Int8
            || obj is Int16
            || obj is Int32
            || obj is Int64
            || obj is UInt
            || obj is UInt8
            || obj is UInt16
            || obj is UInt32
            || obj is UInt64
        {
            return true
        }
        
        if obj is Float
            || obj is Double
            || obj is Bool
            || obj is Character
        {
            return true
        }
        
        // support other StringProtocol(Associated Types)
        if obj is String || obj is Substring {
            return true
        }
        
        // objective-c class support
        if obj is NSValue {
            return true
        }
        
        return false
    }
    
    /// Set property
    open static func set<T: HandyJSON>(_ value:Any,to property:String, of obj: inout T) {
        fill(dic: [property:value], obj: &obj)
    }

    /// fill obj
    open static func fill<T: HandyJSON>(dic:[String:Any], obj:inout T) {
        JSONDeserializer<T>.update(object: &obj, from: dic)
    }
    
    /// fill obj from other obj
    open static func fill<T: HandyJSON>(origin:T, obj:inout T) {
        if let dic = origin.toJSON() {
            fill(dic: dic, obj: &obj)
        }
    }
}

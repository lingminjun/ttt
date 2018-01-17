//
//  Injects.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/15.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

/// reflect //http://www.hangge.com/blog/cache/detail_976.html
final public class Injects {
    
    /// Get the property type. if it is NSNull, may be option type.
    open static func type(property: String,of obj: NSObject) -> Any.Type {
        
        var mr: Mirror = Mirror(reflecting: obj)
        for child in mr.children {
            if child.label! == property {
                return Swift.type(of: child.value)
            }
        }
        while let parent = mr.superclassMirror {
            for child in parent.children {
                if child.label! == property {
                    return Swift.type(of: child.value)
                }
            }
            mr = parent
        }
        return NSNull.Type.self
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
    open static func isBaseType(_ type: Any.Type) -> Bool {
        if type == Int.Type.self
            || type == Int8.Type.self
            || type == Int16.Type.self
            || type == Int32.Type.self
            || type == Int64.Type.self
            || type == UInt.Type.self
            || type == UInt8.Type.self
            || type == UInt16.Type.self
            || type == UInt32.Type.self
            || type == UInt64.Type.self
        {
            return true
        }
        
        if type == Float.Type.self
            || type == Double.Type.self
            || type == Bool.Type.self
            || type == Character.Type.self
        {
            return true
        }
        
        if type == String.Type.self {
            return true
        }
        
        return false
    }
    
    /// Set property
    open static func set(_ value:Any,to property:String, of obj: NSObject) {
        let tb = self.type(property:property,of:obj)
        if tb == NSNull.Type.self {
            print("[\(obj)] without [\(property)]")
        } else if self.isType(obj, type: tb)  {//子类，可以赋值
            obj.setValue(value, forKey: property)
        } else if value is String {
            
        }
    }

    
    
    /// fill填充数据
    public static func fill<T: NSObject>(dic:Dictionary<String,NSObject>, model:T) {
        
        let mirror = Mirror(reflecting: model)
        for (key,value) in dic {
            for item in mirror.children {
                
                if(item.label != nil && item.label! == key){
                    let v = item.value
                    
                    //若无法判断类型
                    let o = type(of: v)
                    let t = type(of: value)
                    if o == t {//类型相同，直接复制
                        model.setValue(v, forKey: key)
                    } else if v is Optional {
                        //针对基础类型
                        do {
                            try model.setValue(value, forKey: key)
                        } catch {
                            print("error:\(error)")
                            model.setValue(v, forKey: key) // restore value
                        }
                    }
                    
                }
            }
        }
    }
}

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
    open static func get(property: String,of obj: NSObject) -> Any? {
        
        var mr: Mirror = Mirror(reflecting: obj)
        for child in mr.children {
            if let label = child.label, label == property {
                return child.value
            }
        }
        
        //recursive
        while let parent = mr.superclassMirror {
            for child in parent.children {
                if let label = child.label, label == property {
                    return child.value
                }
            }
            mr = parent
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
    open static func set<T: NSObject>(_ value:Any,to property:String, of obj: T) {
        guard let oldv = self.get(property:property,of:obj) else {
            print("\(type(of: obj)) without \(property) property")
            return
        }
        if self.isType(obj, type: type(of: oldv))  {//子类，可以赋值
            MMTry.try({ obj.setValue(value, forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
        } else if isBaseType(value) && isBaseType(oldv) {
            let v = "\(value)"
            if oldv is Int { MMTry.try({  obj.setValue(Int(v), forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil) }
            else if oldv is Int8 { MMTry.try({ obj.setValue(Int8(v), forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil) }
            else if oldv is Int16 { MMTry.try({ obj.setValue(Int16(v), forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil) }
            else if oldv is Int32 { MMTry.try({ obj.setValue(Int32(v), forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil) }
            else if oldv is Int64 { MMTry.try({ obj.setValue(Int64(v), forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil) }
            else if oldv is UInt { MMTry.try({ obj.setValue(UInt(v), forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil) }
            else if oldv is UInt8 { MMTry.try({ obj.setValue(UInt8(v), forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil) }
            else if oldv is UInt16 { MMTry.try({ obj.setValue(UInt16(v), forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil) }
            else if oldv is UInt32 { MMTry.try({ obj.setValue(UInt32(v), forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil) }
            else if oldv is UInt64 { MMTry.try({ obj.setValue(UInt64(v), forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil) }
            else if oldv is Float { MMTry.try({ obj.setValue(Float(v), forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil) }
            else if oldv is Double { MMTry.try({ obj.setValue(Double(v), forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil) }
            
            else if oldv is String || oldv is Substring {
                MMTry.try({
                    obj.setValue(v, forKey: property)
                }, catch: { (exception) in
                    print("error:\(String(describing: exception))")
                }, finally: nil)
            }
            
            else if oldv is Bool {
                let bs = v.lowercased()
                if bs == "true" || bs == "yes" || bs == "on" || bs == "1" || bs == "t" || bs == "y" {
                    MMTry.try({ obj.setValue(true, forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
                } else if bs == "false" || bs == "no" || bs == "off" || bs == "0" || bs == "f" || bs == "n" {
                    MMTry.try({ obj.setValue(false, forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
                } else {
                    print("\(type(of: obj))  the \(property) unable to set value [\(v)]")
                }
            }
            else if oldv is Character {
                if v.count == 1 {
                    MMTry.try({ obj.setValue(v[v.startIndex], forKey: property) }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
                } else {
                    print("\(type(of: obj)) the \(property) unable to set value [\(v)]")
                }
            }
            else {
                print("\(type(of: obj)) the \(property) unable to set value [\(v)]")
            }
        } else {
            MMTry.try({
                obj.setValue(value, forKey: property)
            }, catch: { (exception) in
                print("error:\(String(describing: exception))")
                print("\(type(of: obj)) the \(property) unable to set value [\(value)]")
                obj.setValue(oldv, forKey: property) //Reduced value
            }, finally: nil)
        }
    }

    /// fill model
    open static func fill<T: NSObject>(dic:Dictionary<String,Any>, model:T) {
        for (key,value) in dic {
            self.set(value, to: key, of: model)
        }
    }
}

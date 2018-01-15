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
    
    /// fill填充数据
    public func fill<T: NSObject>(dic:Dictionary<String,NSObject>, model:T) {
        
        /// 这里将字典中所有KEY  和 值  都转换为  STRING类型，目的只有一个运用 OBJ的 setValue方法，给 这个对象赋值
        
        /// 这就完成了，字典和对象的转换
        
        let mirrotwo:Mirror = Mirror(reflecting: dic)
        
        for p in mirrotwo.children {
            
            var (key,value) = (p.value as! (String,String))
            
            //循环出字典中的每一对key - value 都是String类型，然后将这个类型赋值给model
            
            //这一次遍历当前需要赋值对象的属性，是因为需要判断当前对象是否有这个属性，如果有才会给他赋值，如果没有就略过
            
            //mirrorModel是当前需要赋值的对象的反射对象，他的LABEL就是对象的属性，value就是数值，但是只读的，
            
            //所以只能通过model.setValue来赋值
            
            let mirrorModel = Mirror(reflecting: model)
            
            for eachItem in mirrorModel.children {
                
                if(eachItem.label! == key){
                    
                    //这一步简直爆炸的方法
                    
                    model.setValue(value, forKey: key)
                    
                }
                
            }
            
        }
        
    }
}

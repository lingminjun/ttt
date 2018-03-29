//
//  NSObjectTagExt.swift
//  ttt
//
//  Created by MJ Ling on 2018/3/29.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

private var OBJ_TAGS_PROPERTY = 0

public extension NSObject {
    //tags，方便一个对象关联其他数据
    public final func ssn_tag(_ key:String) -> Any? {
        guard let dic = objc_getAssociatedObject(self, &OBJ_TAGS_PROPERTY) as? [String:Any] else {  return nil }
        return dic[key]
    }
    public final func ssn_setTag(_ key:String, tag:Any) {
        let dic:[String:Any]!
        if let dis = objc_getAssociatedObject(self, &OBJ_TAGS_PROPERTY) as? [String:Any] {
            dic = dis
        } else {
            dic = [String:Any]()
        }
        dic[key] = tag
        objc_setAssociatedObject(self, &OBJ_TAGS_PROPERTY, dic, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    public final func ssn_delTag(_ key:String) {
        guard var dic = objc_getAssociatedObject(self, &OBJ_TAGS_PROPERTY) as? [String:Any] else {  return }
        dic.removeValue(forKey: key)
        objc_setAssociatedObject(self, &OBJ_TAGS_PROPERTY, dic, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

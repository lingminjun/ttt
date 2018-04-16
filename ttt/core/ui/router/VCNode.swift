//
//  VCNode.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/15.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

public struct VCNode {
    public var controller: String = ""
    public var container: String = "" //限定特定的activity打开，默认UIViewContainer
    
    public var url: String = "" //对应的url
    
    public var path: String = "" //统一资源标识符，主要取url中path 针对特殊如https://m.demo.com/detail/{skuid}.html 去掉 detail/{_}.html 好了
    public var key: String = "" //埋点需要的key---对应另一个配置
    public var des: String = "" //描述
    
    public var params: [String] = [] //主键参数，针对url为 https://m.demo.com/z/{pageId}/{chlId} 这种
    
    public var modal: Bool? = nil//null表示不强制限定打开方式
    public var auth: Bool = false
}

//
//  MMFetchSQLite.swift
//  ttt
//
//  Created by lingminjun on 2018/7/9.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import SQLite.Swift
//直接采用HandyJSON内存赋值模型（不重复造轮子）
import HandyJSON

//public protocol SQLiteModel : HandyJSON,MMCellModel {}

public struct SQLTable {
    public var name:String = ""      //表名
    public var columns:[String] = [] //要展示的字段
    public var on:String = "" //inner join on 字段
    
    public init(name:String, join column:String) {
        self.name = name
        self.on = column
    }
    
    public init(name:String, join column:String, columns:[String]) {
        self.name = name
        self.on = column
        self.columns = columns
    }
}

public final class SQLQuery<T: HandyJSON> {
    
    private var _offset:UInt = 0
    private var _limit:UInt = 0
    private var _predicate:NSPredicate? = nil
    private var _sorts:[NSSortDescriptor] = []
    private var _tables:[String] = [] //关联的表
    private var _sql:String = ""      //单独写sql的情况
    
    //构建单页查询
    public convenience init(table:String,predicate:NSPredicate? = nil, sort:String = "", desc:Bool = false, offset:UInt = 0, limit:UInt = 10000) {
        self.init(table:table,predicate:predicate,sorts:(sort.isEmpty ? [] : [NSSortDescriptor(key: sort, ascending: !desc)]),offset:offset,limit:limit)
    }
    
    //构建单页查询
    public convenience init(table:String,predicate:NSPredicate? = nil, sorts:[NSSortDescriptor] = [], offset:UInt = 0, limit:UInt = 10000) {
        self.init()
    }
    
    //构建单页查询
    public convenience init(table:String, columns:[String] ,predicate:NSPredicate? = nil, sorts:[NSSortDescriptor] = [], offset:UInt = 0, limit:UInt = 10000) {
        self.init()
    }
    
    //构建多表查询，表与表之间采用join on字段关联
    public convenience init(tables:[SQLTable], predicate:NSPredicate? = nil, sorts:[NSSortDescriptor] = [], offset:UInt = 0, limit:UInt = 10000) {
        self.init()
    }
    
    
    
//    - (NSString *)dbTable;//数据查询来源主表
//    
//    - (Class<SSNDBFetchObject>)entity;//数据返回实例，如果你不传入对象，则返回数据项放入字典中
//    
//    - (NSArray *)sortDescriptors;//<NSSortDescriptor *>
//    
//    @property (nonatomic) NSUInteger offset;//起始点，按照sortDescriptors排序的起始值
//    
//    @property (nonatomic) NSUInteger limit;//限制大小，传入0表示无限制
//    
//    - (NSString *)fetchSql;//查询sql
//    
//    - (NSString *)fetchForRowidSql;//查询sql单个数据
}



/// 普通列表管理
public class MMFetchSQLite<T: MMCellModel,HandyJSON>: MMFetch<T> {
    var _list = [T]()
}

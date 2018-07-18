//
//  MMFetchSQLite.swift
//  ttt
//
//  Created by lingminjun on 2018/7/9.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
//直接采用HandyJSON内存赋值模型（不重复造轮子）
import HandyJSON

public struct SQLTable {
    public var name:String = ""      //表名
    public var template:String = ""  //模板名
    public var columns:[String] = [] //要展示的字段
    public var on:String = "" //inner join on 右边字段或左边字段
    public var left:String = "" //inner join on 左边字段
    
    public init(name:String, template:String = "") {
        self.name = name
        self.template = template
    }
    
    public init(name:String, join column:String, template:String = "") {
        self.name = name
        self.on = column
        self.template = template
    }
    
    public init(name:String, columns:[String], template:String = "") {
        self.name = name
        self.columns = columns
        self.template = template
    }
    
    public init(name:String, join left:String, on column:String, template:String = "") {
        self.name = name
        self.left = left
        self.on = column
        self.template = template
    }
    
    public init(name:String, join column:String, columns:[String], template:String = "") {
        self.name = name
        self.on = column
        self.columns = columns
        self.template = template
    }
    
    public init(name:String, join left:String, on column:String, columns:[String], template:String = "") {
        self.name = name
        self.left = left
        self.on = column
        self.columns = columns
        self.template = template
    }
}

public struct SQLQuery<T: HandyJSON> {
    
    //构建单页查询
    public init(table:String, template:String = "", predicate:NSPredicate? = nil, specified set:(String,[Binding])? = nil, sort:String = "", desc:Bool = false, offset:UInt = 0, limit:UInt = 10000) {
        self.init(table:table,template:template,specified:set,predicate:predicate,sorts:(sort.isEmpty ? [] : [NSSortDescriptor(key: sort, ascending: !desc)]),offset:offset,limit:limit)
    }
    
    //构建单页查询
    public init(table:String, columns:[String] = [],template:String = "", specified set:(String,[Binding])? = nil, predicate:NSPredicate? = nil, sorts:[NSSortDescriptor] = [], offset:UInt = 0, limit:UInt = 10000) {
        self.init(tables: [SQLTable(name: table,columns: columns, template:template)], specified:set, predicate: predicate, sorts: sorts, offset: offset, limit: limit)
    }
    
    //构建多表查询，表与表之间采用join on字段关联，若
    public init(tables:[SQLTable], predicate:NSPredicate? = nil, sorts:[NSSortDescriptor] = [], offset:UInt = 0, limit:UInt = 10000) {
        self.init(tables: tables, predicate: predicate, sorts: sorts, offset: offset, limit: limit)
    }
    
    private init(tables:[SQLTable], specified set:(String,[Binding])? = nil, predicate:NSPredicate? = nil, sorts:[NSSortDescriptor] = [], offset:UInt = 0, limit:UInt = 10000) {
        self._tables = tables
        self.predicate = predicate
        self.sorts = sorts
        self.offset = offset
        self.limit = limit
        if let set = set {
            self.limitColumn = set.0
            self.limitSet = set.1
        }
    }
    
    //构建sql模式
    public init(sql:String) {
        
        //取关联table
        var begin = sql.startIndex
        let end = sql.endIndex
        var tbs:[SQLTable] = []
        while true {
            if let range = sql.range(of: "from\\s+\\w*", options: [.regularExpression,.caseInsensitive], range:begin..<end) {
                tbs.append(SQLTable(name: "\(sql[range])"))
                begin = range.upperBound
            } else {
                break
            }
        }
        
        var ssql = sql
        if let range = ssql.range(of: "SELECT ", options:.caseInsensitive) {
            if tbs.count > 1 {
                ssql = ssql.replacingOccurrences(of: "SELECT", with: "SELECT \(tbs[0]).rowid AS ssn_rowid,", options: .caseInsensitive, range: range)
            } else {
                ssql = ssql.replacingOccurrences(of: "SELECT", with: "SELECT rowid AS ssn_rowid,", options: .caseInsensitive, range: range)
            }
        }
        
        self._tables = tbs
        self._sql = ssql
    }
    
    public init() {}
    
    public var offset:UInt = 0
    public var limit:UInt = 0
    public var predicate:NSPredicate? = nil
    public var sorts:[NSSortDescriptor] = []
    public var tableNames:[String] { //关联的表
        var tbs:[String] = []
        for idx in 0..<self._tables.count {
            let tb = self._tables[idx]
            if tb.name.isEmpty { continue }
            tbs.append(tb.name)
        }
        return tbs
    }
    public var sql:String {
        if !_sql.isEmpty {
            return _sql
        }
        
        return buildSql()
    }
    public var describe:String {
        var str = "query data from "
        for idx in 0..<self._tables.count {
            let tb = self._tables[idx]
            if tb.name.isEmpty { continue }
            if idx > 0 { str = str + "," }
            str = str + tb.name
        }
        return str
    }
    
    public var limitColumn:String = ""
    public var limitSet:[Binding]? = nil
    public var isSpecifiedSet:Bool {
        return !limitColumn.isEmpty && limitSet != nil
    }
    private var _sql:String = ""      //单独写sql的情况
    private var _tables:[SQLTable] = []
    public var tables:[SQLTable] { //关联的表
        return _tables
    }
    private func buildSql() -> String {
        //构建sql
        var sql = ""
        
        // 分析表数据
        sql = sql + selectColumnSqlFragment()
        
        // 数据源
        sql = sql + fromTableSqlFragment()
        
        // 条件
        sql = sql + whereSqlFragment()
        
        // 排序
        sql = sql + orderBySqlFragment()
        
        // 限制行数
        sql = sql + limitSqlFragment()

        return sql
    }
    
    // rowid查询单个数据sql编写
    public func buildFetchObjectByRowidSqlPrepare() -> String {
        
        var sql = selectColumnSqlFragment()
        // 数据源
        sql = sql + fromTableSqlFragment()
        
        // 条件语句
        let wheresql = whereSqlFragment()
        if wheresql.isEmpty {
             sql = sql + " WHERE ( rowid = ? ) "
        } else {
            sql = sql + wheresql + " AND ( rowid = ? ) "
        }
        
        //只取一条数据
         sql = sql + " LIMIT 0,1 "
        
        return sql
    }
    
    public func buildFetchRowidSqlPrepare(for otherTable:String) -> String {
        var idx = 0
        var tb1:SQLTable? = nil
        for tb in self._tables {
            if tb.name.isEmpty { continue }
            
            if idx == 0 {
                tb1 = tb
            }
            
            if tb.name == otherTable {
                break
            }
            idx = idx + 1
        }
        
        guard let mainTb = tb1 else {
            return ""
        }
        
        //就是当前表，无意义
        if idx == 0 {
            return "SELECT DISTINCT tbl0.rowid AS ssn_rowid FROM \(mainTb.name) as tbl0 WHERE tbl0.rowid = ?"
        }
        
        var sql = "SELECT DISTINCT tbl0.rowid AS ssn_rowid "
        
        // 数据源
        sql = sql + fromTableSqlFragment()
        
        // 条件语句
        let wheresql = whereSqlFragment()
        if wheresql.isEmpty {
            sql = sql + " WHERE ( \(idx).rowid = ? ) "
        } else {
            sql = sql + wheresql + " AND ( \(idx).rowid = ? ) "
        }
        
        return sql
    }
    
    public func selectColumnSqlFragment() -> String {
        var set:Set<String> = Set<String>()
        
        // 分析表数据
        var sql = "SELECT tbl0.rowid AS ssn_rowid"
        var idx = 0
        for tb in self._tables {
            if tb.name.isEmpty { continue }
            
            //字段分类
            if tb.columns.isEmpty {
                sql = sql + ", tbl\(idx).*"
            } else {
                for cl in tb.columns {
                    if !cl.isEmpty && !set.contains(cl) {
                        sql = sql + ", "
                        sql = sql + "tbl\(idx).\(cl) AS \(cl)"
                        set.insert(cl)
                    }
                }
            }
            
            idx = idx + 1
        }
        
        return sql
    }
    
    public func fromTableSqlFragment() -> String {
        var sql = " FROM "
        var idx = 0
        for tb in self._tables {
            if tb.name.isEmpty { continue }
            if idx > 0 {
                sql = sql + ", "
            }
            sql = sql + "\(tb.name) AS tbl\(idx)"
            idx = idx + 1
        }
        return sql
    }
    
    public func whereSqlFragment() -> String {
        var tbs:[String] = []
        var joins:[String] = []
        
        // 分析表数据
        for idx in 0..<self._tables.count {
            let tb = self._tables[idx]
            if tb.name.isEmpty { continue }
            tbs.append(tb.name)
            
            if idx <= 1 {
                continue
            }
            
            let tb1 = "tbl\(idx - 1)"
            let tb2 = "tbl\(idx)"
            if !tb.on.isEmpty {
                if tb.left.isEmpty {
                    joins.append("\(tb1).\(tb.on) = \(tb2).\(tb.on)")
                } else {
                    joins.append("\(tb1).\(tb.left) = \(tb2).\(tb.on)")
                }
            }
        }
        
        if joins.isEmpty && predicate == nil && !self.isSpecifiedSet {
            return ""
        }
        
        var sql = " WHERE "
        for idx in 0..<joins.count {
            let join = joins[idx]
            if idx > 0 {
                sql = sql + " AND "
            }
            
            if joins.count > 1 && idx == 0 {
                sql = sql + " ( "
            }
            
            sql = sql + join
            
            if joins.count > 1 && idx + 1 == joins.count {
                sql = sql + " ) "
            }
        }
        
        // 指定集合
        var hasSet = false
        if let limitSet = self.limitSet, !limitColumn.isEmpty {
            var values = ""
            for bind in limitSet {
                if !values.isEmpty {
                    values = values + ","
                }
                if let str = bind as? String {
                    values = values + "'\(str)'"
                } else {
                    values = values + "\(bind)"
                }
            }
            hasSet = true
            if joins.count > 0 {
                sql = sql + " AND ( tbl0.\(limitColumn) in ( \(values) ) )"
            } else {
                sql = sql + " ( tbl0.\(limitColumn) in ( \(values) ) )"
            }
        }
        
        // 其他条件
        if let predicate = predicate {
            if joins.count > 0 || hasSet {
                sql = sql + " AND ( \(predicate.predicateFormat) )"
            } else {
                sql = sql + " ( \(predicate.predicateFormat) )"
            }
        }
        
        return sql
    }
    
    public func orderBySqlFragment() -> String {
        if sorts.count <= 0 {
            return ""
        }
        var sql = " ORDER BY "
        for idx in 0..<sorts.count {
            let sort = sorts[idx]
            if let key = sort.key, !key.isEmpty {
                if idx > 0 {
                    sql = sql + ", "
                }
                let asc = sort.ascending ? "ASC" : "DESC"
                sql = sql + "\(key) \(asc)"
            }
        }
        return sql
    }
    
    public func limitSqlFragment() -> String {
        if limit > 0 {
            return " LIMIT \(offset),\(limit)"
        }
        return ""
    }
    
}

public typealias SQLiteModel = DBModel & MMCellModel


fileprivate class SQLiteItem : HandyJSON {
    var ssn_rowid:Int64 = -1
    required init() {
        
    }
}

// MARK: sqlite fetch 实现
public class MMFetchSQLite<T: SQLiteModel> : MMFetch<T> {
    
    private var _list = [T]()
    private var _load = false
    private var _query:SQLQuery<T> = SQLQuery<T>()
    private var _db:DB!
    private var _tables:[String] = []
    
//    override public init(tag:String) {
//        super.init(tag: tag)
//    }
    
    public init(query: SQLQuery<T>, db:DB) {
        super.init(tag: "sqlite:" + query.describe)
        _query = query
        _db = db
        _tables = _query.tableNames
        
        //监听
        NotificationCenter.default.addObserver(self, selector: #selector(MMFetchSQLite.tableUpdateNotice(notfication:)), name: SQLITE_UPDATED_NOTICE, object: db)
        
        load()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func tableUpdateNotice(notfication: NSNotification) {
        //消息转发，仅仅关注此表修改
        if let info = notfication.userInfo, let table = info[SQLITE_TABLE_KEY] as? String, self._tables.contains(table) {
            //监听修改
            guard let rowid = info[SQLITE_ROW_ID_KEY] as? Int64, let opt = info[SQLITE_OPERATION_KEY] as? DB.Operation else {
                return
            }
            
            self.handleNotice(table: table, operation: opt, rowid: rowid)
        }
    }
    
    private func load() {
        if _load {
            return
        }
        
        //先检查表是否创建，防止表未创建
        for tb in self._query.tables {
            let _ = DBTable.table(db: _db, name: tb.name, template:tb.template )
        }
        
        //查询数据
        let sql = _query.sql
        let objs = self._db.prepare(type: T.self, sql: sql, args: [])
        _list.append(contentsOf: objs)
        _load = true
    }
    
    private func handleNotice(table:String, operation:DB.Operation, rowid:Int64) {
        switch operation {
        case .insert:
            handleInsertNotice(table: table, rowid: rowid)
            break
        case .update:
            handleUpdateNotice(table: table, rowid: rowid)
            break
        case .delete:
            handleDeleteNotice(table: table, rowid: rowid)
            break
        }
    }
    
    private func handleInsertNotice(table:String, rowid:Int64) {
        if _tables.count <= 1 {
            //如何寻找插入位置？
            let objs = self._db.prepare(type: T.self, sql: self._query.buildFetchObjectByRowidSqlPrepare(), args: [rowid])
            if objs.count > 0 {//表示此数据符合此列表过滤，寻找插入位置
                if let idx = indexOf(rowid: rowid) {
                    let obj = objs[0]
                    self.operation(updates: { (section) -> [IndexPath] in
                        guard let _ = self[idx] else { return [] }
                        self._list[idx] = obj
                        return [IndexPath(row:idx,section:section)]
                    }, animated:nil)
                } else {
                    let objs = self._db.prepare(type: T.self, sql: self._query.sql, args: [])
                    let item = SQLiteItem()
                    item.ssn_rowid = rowid
                    handleResetNotice(objs: objs, uprowids: [item])
                }
            }
        } else {
            let items = self._db.prepare(type: SQLiteItem.self, sql: _query.buildFetchRowidSqlPrepare(for: table), args: [rowid])
            let objs = self._db.prepare(type: T.self, sql: self._query.sql, args: [])
            handleResetNotice(objs: objs, uprowids: items)
        }
    }
    
    private func handleUpdateNotice(table:String, rowid:Int64) {
        if _tables.count <= 1 {
            //查找对应的数据
            if let idx = indexOf(rowid: rowid) {
                let objs = self._db.prepare(type: T.self, sql: self._query.buildFetchObjectByRowidSqlPrepare(), args: [rowid])
                if objs.count > 0 {
                    let obj = objs[0]
                    self.operation(updates: { (section) -> [IndexPath] in
                        guard let _ = self[idx] else { return [] }
                        self._list[idx] = obj
                        return [IndexPath(row:idx,section:section)]
                    }, animated:true)
                } else {// 找不到说明针对此列表而言，已经删除
                    self.operation(deletes: { (section) -> [IndexPath] in
                        self._list.remove(at: idx)
                        return [IndexPath(row:idx,section:section)]
                    }, animated:nil)
                }
            }
        } else {
            let items = self._db.prepare(type: SQLiteItem.self, sql: _query.buildFetchRowidSqlPrepare(for: table), args: [rowid])
            let objs = self._db.prepare(type: T.self, sql: self._query.sql, args: [])
            handleResetNotice(objs: objs, uprowids: items)
        }
    }
    
    private func handleDeleteNotice(table:String, rowid:Int64) {
        //单表场景，容易处理
        if _tables.count <= 1 {
            //删除数据，查找对应的数据
            if let idx = indexOf(rowid: rowid) {
                self.operation(deletes: { (section) -> [IndexPath] in
                    self._list.remove(at: idx)
                    return [IndexPath(row:idx,section:section)]
                }, animated:nil)
            }
        } else {
            let items = self._db.prepare(type: SQLiteItem.self, sql: _query.buildFetchRowidSqlPrepare(for: table), args: [rowid])
            let objs = self._db.prepare(type: T.self, sql: self._query.sql, args: [])
            handleResetNotice(objs: objs, uprowids: items)
        }
    }
    
    private func handleResetNotice(objs:[T],uprowids:[SQLiteItem]) {
        //计算更改
        let steps = _list.ssn_diff(objs) { (r, l) -> Bool in
            return r.ssn_rowid == l.ssn_rowid
        }
        
        var dels:[Diff.Step<[T]>] = []
        var inss:[Diff.Step<[T]>] = []
        var upds:[Diff.Step<[T]>] = []
        
        var ids:Set<Int64> = Set<Int64>()
        for item in uprowids {
            ids.insert(item.ssn_rowid)
        }
        
        for step in steps {
            if step.operation == .delete {
                dels.append(step)
            } else if step.operation == .insert {
                inss.append(step)
            } else if let obj = step.from, ids.contains(obj.ssn_rowid) {
                upds.append(step)
            }
        }
        
        self.operation(deletes: { (section) -> [IndexPath] in
            var rt:[IndexPath] = []
            for step in dels {
                self._list.remove(at: step.fromIndex)
                rt.append(IndexPath(row:step.fromIndex,section:section))
            }
            return rt
        }, inserts: { (section) -> [IndexPath] in
            var rt:[IndexPath] = []
            for step in inss {
                if let obj = step.to {
                    self._list.insert(obj, at: step.toIndex)
                    rt.append(IndexPath(row:step.toIndex,section:section))
                }
            }
            return rt
        }, updates: { (section) -> [IndexPath] in
            var rt:[IndexPath] = []
            for step in upds {
                rt.append(IndexPath(row:step.fromIndex,section:section))
            }
            return rt
        }, animated: nil)
    }
    
    private func indexOf(rowid:Int64) -> Int? {
        for idx in 0..<_list.count {
            let obj = _list[idx]
            
            //表示找到删除
            if obj.ssn_rowid == rowid {
                return idx
            }
        }
        return nil
    }
    
    /// Derived class implements
    public override func count() -> Int {
        return _list.count
    }
    public override func objects/*<S: SequenceType where S.Generator.Element: Object>*/() -> [T]? { return Array(_list)}
    
    /// Update
    public override func update(_ idx: Int, newObject: T? = nil, animated:Bool? = nil) {
        if let _ = newObject {//直接走数据库
            print("请直接操作DBTable, FetchSQLite暂不支持委托操作")
        } else {// 仅仅通知更新
            self.operation(updates: { (section) -> [IndexPath] in
                guard let _ = self[idx] else { return [] }
                return [IndexPath(row:idx,section:section)]
            }, animated:animated)
        }
    }
    /// 指定结果集可插入新的数据，注意：SQLite Fetch并不委托操作数据表
    public override func insert<C: Sequence>(_ newObjects: C, atIndex i: Int, animated:Bool? = nil) where C.Iterator.Element == T {
        if _query.isSpecifiedSet {
            let values = filterSpecifiedSet(newObjects)
            
            if !values.isEmpty {
                var idx = i
                //compatibility out boundary
                if let set = self._query.limitSet, i < 0 || i > set.count {
                    idx = set.count
                }
                self._query.limitSet?.insert(contentsOf: values, at: idx)
                
                let objs = self._db.prepare(type: T.self, sql: self._query.sql, args: [])
                handleResetNotice(objs: objs, uprowids: [])
            }
        } else {
            print("请直接操作DBTable, FetchSQLite暂不支持委托操作")
        }
    }
    
    /// 指定结果集可重置数据， 注意：SQLite Fetch并不委托操作数据表
    public override func reset<C>(_ newObjects: C, animated:Bool? = nil) where T == C.Element, C : Sequence {
        if _query.isSpecifiedSet {
            let values = filterSpecifiedSet(newObjects)
            self._query.limitSet? = values
            
            let objs = self._db.prepare(type: T.self, sql: self._query.sql, args: [])
            //重置数据，需要通知列表所有数据将更新
            var uprowids:[SQLiteItem] = []
            for obj in objs {
                let item = SQLiteItem()
                item.ssn_rowid = obj.ssn_rowid
                uprowids.append(item)
            }
            handleResetNotice(objs: objs, uprowids: uprowids)
        } else {
            print("请直接操作DBTable, FetchSQLite暂不支持委托操作")
        }
    }
    
    /// 指定结果集可删除数据，注意：SQLite Fetch并不委托操作数据表
    public override func delete(_ index: Int, length: Int, animated:Bool? = nil) {
        if _query.isSpecifiedSet {
            var range = Range<Int>(uncheckedBounds: (0, 0))
            //compatibility out boundary
            if let set = self._query.limitSet {
                if index >= set.count {//不合法的数据
                    return
                }
                
                let end = (index + length >= set.count) ? set.count : (index + length)
                range = Range<Int>(uncheckedBounds: (index, end))
            }
            
            if range.count > 0 {
                self._query.limitSet?.removeSubrange(range)
                let objs = self._db.prepare(type: T.self, sql: self._query.sql, args: [])
                handleResetNotice(objs: objs, uprowids: [])
            }
        } else {
            print("请直接操作DBTable, FetchSQLite暂不支持委托操作")
        }
    }
    
    
    /// 指定结果集可清除数据，注意：SQLite Fetch并不委托操作数据表
    public override func clear(animated:Bool? = nil) {
        if _query.isSpecifiedSet {
            guard let set = self._query.limitSet else {
                return
            }
            if set.isEmpty {
                return
            }
            self._query.limitSet?.removeAll()
            let objs = self._db.prepare(type: T.self, sql: self._query.sql, args: [])
            handleResetNotice(objs: objs, uprowids: [])
        } else {
            print("请直接操作DBTable, FetchSQLite暂不支持委托操作")
        }
    }
    
    private func filterSpecifiedSet<C>(_ newObjects: C) -> [Binding] where T == C.Element, C : Sequence {
        var values:[Binding] = []
        for obj in newObjects {
            if let value = Injects.get(property: self._query.limitColumn, of: obj) as? Binding {
                values.append(value)
            }
        }
        return values
    }
    
    /// Get element at index. Derived class implements.
    public override func get(_ index: Int) -> T? {
        if index < 0 || index >= _list.count {
            return nil
        }
        
        return _list[index]
    }
    
    /// Returns the index of an object in the results collection. Derived class implements.
    public override func indexOf(_ object: T) -> Int? {
        for idx in 0..<_list.count {
            if _list[idx] === object {// FIX ME
                return idx;
            }
        }
        return nil
    }
    public override func filter(_ predicate: NSPredicate) -> [T] {
        return _list.filter({ (obj) -> Bool in
            return predicate.evaluate(with: obj)
        })
    }
}

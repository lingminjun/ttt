//
//  DBTable.swift
//  ttt
//
//  Created by lingminjun on 2018/7/7.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

#if SQLITE_SWIFT_STANDALONE
import sqlite3
#elseif SQLITE_SWIFT_SQLCIPHER
import SQLCipher
#elseif os(Linux)
import CSQLite
#else
import SQLite3
#endif

import HandyJSON

//通知定义 (主线程)
//let DBTABLE_WILL_MIGRARE_NOTICE = NSNotification.Name(rawValue:"DBTable.will.Migrate")
//let DBTABLE_DID_MIGRARE_NOTICE = NSNotification.Name(rawValue:"DBTable.did.Migrate")
//let DBTABLE_DID_DROP_NOTICE = NSNotification.Name(rawValue:"DBTable.did.Drop")

let DBTABLE_DATA_CHANGED_NOTICE = NSNotification.Name(rawValue:"DBTable.Data.Changed")

/*
JSON方式 实现table 版本管理
json文件定义:与数据SSNDBColumn对应
下面定义仅供参考，数据结构并非合理，主要注意type、level和index的值设置
{
    "tb":"Person",
    "its":[{
    "vs":1,
    "cl":[  {"name":"uid",    "type":"Int",   "level":"Primary",  "fill":"",  "index":"Index",   "mapping":""},
            {"name":"name",   "type":"Text",  "level":"NotNull",  "fill":"",  "index":"Unique",  "mapping":""},
            {"name":"sex",    "type":"Bool",  "level":"",         "fill":"",  "index":"",        "mapping":""},
            {"name":"height", "type":"Float", "level":"",         "fill":"",  "index":"",        "mapping":""},
            {"name":"avatar", "type":"Blob",  "level":"",         "fill":"",  "index":"",        "mapping":""},
            {"name":"other",  "type":"Null",  "level":"",         "fill":"",  "index":"",        "mapping":""}
    ]
    },
    {
    "vs":2,
    "cl":[  {"name":"uid",    "type":"Int",   "level":"Primary",  "fill":"",  "index":"Index",   "mapping":""},
            {"name":"name",   "type":"Text",  "level":"NotNull",  "fill":"",  "index":"Unique",  "mapping":""},
            {"name":"sex",    "type":"Bool",  "level":"",         "fill":"",  "index":"",        "mapping":""},
            {"name":"height", "type":"Float", "level":"",         "fill":"",  "index":"",        "mapping":""},
            {"name":"avatar", "type":"Blob",  "level":"",         "fill":"",  "index":"",        "mapping":""},
            {"name":"mobile", "type":"Text",  "level":"",         "fill":"",  "index":"Index",   "mapping":""},
            {"name":"other",  "type":"Null",  "level":"",         "fill":"",  "index":"",        "mapping":""}
    ]
    }]
}*/

public class DBTableDefinition:HandyJSON {
    var tb:String = ""
    var its:[DBTableTemplate] = []
    public required init() {
    }
    
    public func lastVersion() -> UInt {
        var version:UInt = 0
        for template in self.its.reversed() {
            if template.vs > version {
                version = template.vs
            }
        }
        return version
    }
    
    public func columns(for version:UInt) -> [DBColumn] {
        var cols:[DBColumn] = []
        for template in self.its.reversed() {
            if template.vs == version {
                for col in template.cl {
                    let tableCol = DBColumn(definition: col)
                    cols.append(tableCol)
                }
            }
        }
        return cols
    }
}

public class DBTableTemplate:HandyJSON {
    //json解析
    var vs:UInt = 0
    var cl:[DBTableColumnDefinition] = []
    
    public required init() {
    }
}

public class DBTableColumnDefinition:HandyJSON {
    var name:String = ""
    var type:String = ""
    var level:String = ""
    var fill:String = ""
    var index:String = ""
    var mapping:String = ""
    
    public required init() {
    }
}

public enum DBTableStatus:Int {
    case none = 0,// 表未创建
    update = 1,   //待更新
    ok = 2        //已经是可操作的表
}

//数据实体对象
public protocol DBModel : HandyJSON {
    var ssn_rowid:Int64 { get set }
}

// 数据库表托管对象
public final class DBTable : Equatable {
    public var name:String {    //名字
        return !_tableName.isEmpty ? _tableName : _tableDef.tb
    }
    
    public var version:UInt {
        return _lastVersion
    }
    
    public var isTemplate:Bool {
        return _isTemplate
    }
    
    public var primarieColumnName:[String] {
        return _primaries
    }
    
    public var columnNames:[String] {
        var keys:[String] = []
        keys.append(contentsOf: _columnDict.keys)
        return keys
    }
    
    //私有参数
    private var _isTemplate = true
    private var _db:DB? = nil        //关联的db
    
    //仅仅非模板可使用
    private var db:DB {
        return _db!
    }
    
    private var _tableDef:DBTableDefinition = DBTableDefinition()
    private var _tableName:String = ""
    private var _columns:[DBColumn] = []
    private var _lastVersion:UInt = 0    //最终版本
    private var _primaries:[String] = [] // addObject:cl.name];
    private var _columnDict:[String:DBColumn] = [:]   //
    private var _status:DBTableStatus = .none
    
    
    // 创建可执行操作表（注入链接）
    public convenience init(db:DB, tableJSONDescription url:URL) {
        self.init(tableJSONDescription:url)
        self._isTemplate = false
        //        NSAssert(db && path, @"创建数据表实例参数非法");
        self._db = db
        DBTable.checkCreateTableLog(db:db)
        
        // 4、检查表状态并更新
        DBTable.upgrade(db: db, table: self.name, table: self._tableDef)
        self._status = .ok
        
        // 5、监听变化,分发监听
        NotificationCenter.default.addObserver(self, selector: #selector(DBTable.tableUpdateNotice(notfication:)), name: SQLITE_UPDATED_NOTICE, object: db)
    }
    
    // 创建分表场景需要
    public convenience init(db:DB, template table:DBTable, name:String) {
        self.init()
        _isTemplate = false
        
        // 1、同步模板数据
        self._tableDef = table._tableDef
        self._lastVersion = _tableDef.lastVersion()
        self._columns = _tableDef.columns(for: _lastVersion)
        self._primaries = DBColumn.primaries(columns: _columns)
        self._columnDict = DBColumn.columnNames(columns: _columns)
        self._tableName = name
        
        // 2、设置db
        self._db = db
        DBTable.checkCreateTableLog(db:db)
        
        // 4、检查表状态并更新
        DBTable.upgrade(db: db, table: self.name, table: self._tableDef)
        self._status = .ok
        
        // 5、监听变化,分发监听
        NotificationCenter.default.addObserver(self, selector: #selector(DBTable.tableUpdateNotice(notfication:)), name: SQLITE_UPDATED_NOTICE, object: db)
    }
    
    //TemplateTable
    public convenience init(tableJSONDescription url:URL) {
        self.init()
        self._isTemplate = true
        
        // 1、解析数据表描述
        guard let data = try? Data(contentsOf: url),
            let json = String(data: data, encoding: String.Encoding.utf8),
            let tableDef = DBTableDefinition.deserialize(from: json) else {
                fatalError("请确检查设置的数据表描述文件格式正确")
        }
        
        // 2、缓存列名
        self._tableDef = tableDef
        self._lastVersion = _tableDef.lastVersion()
        self._columns = _tableDef.columns(for: _lastVersion)
        self._primaries = DBColumn.primaries(columns: _columns)
        self._columnDict = DBColumn.columnNames(columns: _columns)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func tableUpdateNotice(notfication: NSNotification) {
        //消息转发，仅仅关注此表修改
        if let info = notfication.userInfo, let table = info[SQLITE_TABLE_KEY] as? String, table == self.name {
            NotificationCenter.default.post(name: DBTABLE_DATA_CHANGED_NOTICE, object: self, userInfo: info)
        }
    }
    
    // 更新并创建表
    public func update() {
        if _status != .ok && _db != nil {
            DBTable.upgrade(db: self.db, table: self.name, table: self._tableDef)
            _status = .ok
        }
    }
    
    public func drop() { //删除数据表
        if _db == nil || _status != .ok {
            return
        }
        
        let table = self.name
        let sql = "DROP TABLE \(table)"
        self.db.transaction { (db) in
            db.execute(sql)
            
            //移除表记录
            DBTable.removeVersion(db: db, for: table)
        }
        _status = .none
    }
    

    //接管db操作
    public func insert<T>(object:T) where T : HandyJSON {
        handleInsert(objects: [object])
    }
    
    public func insert<S: Sequence>(objects:S) where S.Iterator.Element : HandyJSON {
        handleInsert(objects: objects)
    }
    
    /// 兼容协议调用接口
    public func insert(object:HandyJSON) {
        handleInsert(objects: [object])
    }
    
    /// 兼容协议调用接口
    public func insert<S: Sequence>(objects:S) where S.Iterator.Element == HandyJSON {
        handleInsert(objects: objects)
    }
    
    private func handleInsert<S: Sequence>(objects:S) where S.Iterator.Element : Any {
        self.db.transaction { (db) in
            //遍历对象
            for entity in objects {
                guard let obj = entity as? HandyJSON else { continue }
                
                let kv = DBTable.validFieldValue(obj: obj, column: self._columnDict)
                if kv.count == 0 {
                    continue
                }
                var keystr = ""
                var valstr = ""
                var valary:[Binding?] = []
                
                for (key,value) in kv {
                    if !keystr.isEmpty {
                        keystr = keystr + ","
                        valstr = valstr + ","
                    }
                    keystr = keystr + "\(key)"
                    valstr = valstr + "?"
                    valary.append(value)
                }
                
                db.prepare(sql: "INSERT INTO \(self.name) ( \(keystr) ) VALUES( \(valstr) )", args: valary)
            }
        }
    }

    public func update<T>(object:T) where T : HandyJSON {
        handleUpdate(objects: [object])
    }
    
    public func update<S: Sequence>(objects:S) where S.Iterator.Element : HandyJSON {
        handleUpdate(objects: objects)
    }
    
    /// 兼容协议调用接口
    public func update(object:HandyJSON) {
        handleUpdate(objects: [object])
    }
    
    /// 兼容协议调用接口
    public func update<S: Sequence>(objects:S) where S.Iterator.Element == HandyJSON {
        handleUpdate(objects: objects)
    }
    
    private func handleUpdate<S: Sequence>(objects:S) where S.Iterator.Element : Any {
        self.db.transaction { (db) in
            //遍历对象
            for entity in objects {
                guard let obj = entity as? HandyJSON else { continue }
                
                let kv = DBTable.validFieldValue(obj: obj, column: self._columnDict)
                if kv.count == 0 {
                    continue
                }
                
                var keystr = ""
                var valary:[Binding?] = []
                
                //赋值语句
                for (key,value) in kv {
                    //不取主键
                    if let col = self._columnDict[key], col.level != .primary {
                        if !keystr.isEmpty {
                            keystr = keystr + ","
                        }
                        keystr = keystr + "\(key) = ?"
                        valary.append(value)
                    }
                }
                
                // 条件语句
                var wherestr = ""
                for colName in self._primaries {
                    if !wherestr.isEmpty {
                        wherestr = wherestr + " AND "
                    }
                    wherestr = wherestr + "\(colName) = ?"
                    valary.append(kv[colName])
                }
                
                db.prepare(sql: "UPDATE \(self.name) SET \(keystr) WHERE \(wherestr)", args: valary)
            }
        }
    }
    
    public func delete<T>(object:T) where T : HandyJSON {
        handleDelete(objects: [object])
    }
    
    public func delete<S: Sequence>(objects:S) where S.Iterator.Element : HandyJSON {
        handleDelete(objects: objects)
    }
    
    /// 兼容协议调用接口
    public func delete(object:HandyJSON) {
        handleDelete(objects: [object])
    }
    
    /// 兼容协议调用接口
    public func delete<S: Sequence>(objects:S) where S.Iterator.Element == HandyJSON {
        handleDelete(objects: objects)
    }
    
    private func handleDelete<S: Sequence>(objects:S) where S.Iterator.Element : Any {
        self.db.transaction { (db) in
            //遍历对象
            for entity in objects {
                guard let obj = entity as? HandyJSON else { continue }
                
                let kv = DBTable.validFieldValue(obj: obj, column: self._columnDict)
                if kv.count == 0 {
                    continue
                }
                // 条件语句
                var wherestr = ""
                var valary:[Binding?] = []
                for colName in self._primaries {
                    if !wherestr.isEmpty {
                        wherestr = wherestr + " AND "
                    }
                    wherestr = wherestr + "\(colName) = ?"
                    valary.append(kv[colName])
                }
                
                db.prepare(sql: "DELETE FROM \(self.name) WHERE \(wherestr)", args: valary)
            }
        }
    }
    
    public func delete(primary column:String, value:Binding) {
        db.prepare(sql: "DELETE FROM \(self.name) WHERE \(column) = ?", args: [value])
    }
    
    public func upinsert<T>(object:T) where T : HandyJSON {
        handleUpinsert(objects: [object])
    }
    
    public func upinsert<S: Sequence>(objects:S) where S.Iterator.Element : HandyJSON {
        handleUpinsert(objects: objects)
    }
    
    /// 兼容协议调用接口
    public func upinsert(object:HandyJSON) {
        handleUpinsert(objects: [object])
    }
    
    /// 兼容协议调用接口
    public func upinsert<S: Sequence>(objects:S) where S.Iterator.Element == HandyJSON {
        handleUpinsert(objects: objects)
    }
    
    // 由于swift泛型无法解释类型和类型派生
    private func handleUpinsert<S: Sequence>(objects:S) where S.Iterator.Element : Any {
        self.db.transaction { (db) in
            //遍历对象
            for entity in objects {
                guard let obj = entity as? HandyJSON else { continue }
                
                let kv = DBTable.validFieldValue(obj: obj, column: self._columnDict)
                if kv.count == 0 {
                    continue
                }
                
                var upkeystr = ""
                var upvalary:[Binding?] = []
                
                var inkeystr = ""
                var invalstr = ""
                var invalary:[Binding?] = []
                
                //赋值语句
                for (key,value) in kv {
                    //不取主键
                    if let col = self._columnDict[key], col.level != .primary {
                        //更新
                        if !upkeystr.isEmpty {
                            upkeystr = upkeystr + ","
                        }
                        upkeystr = upkeystr + "\(key) = ?"
                        upvalary.append(value)
                    }
                    
                    //插入所有字段
                    if !inkeystr.isEmpty {
                        inkeystr = inkeystr + ","
                        invalstr = invalstr + ","
                    }
                    inkeystr = inkeystr + "\(key) = ?"
                    invalstr = invalstr + "?"
                    invalary.append(value)
                }
                
                // 条件语句
                var wherestr = ""
                for colName in self._primaries {
                    if !wherestr.isEmpty {
                        wherestr = wherestr + " AND "
                    }
                    wherestr = wherestr + "\(colName) = ?"
                    upvalary.append(kv[colName])
                }
                
                db.prepare(sql: "UPDATE \(self.name) SET \(upkeystr) WHERE \(wherestr)", args: upvalary)
                db.prepare(sql: "INSERT INTO \(self.name) ( \(inkeystr) ) VALUES( \(invalstr) )", args: invalary)
            }
        }
    }

    public func object<T: HandyJSON>(_ type:T.Type, predicate:NSPredicate) -> T? {
        //无法使用format
        let objs = objects(type, predicate: predicate)
        return objs.first
    }
    
    public func object<T: HandyJSON>(_ type:T.Type, conditions:[String:Binding?]) -> T? {
        let objs = objects(type, conditions: conditions)
        return objs.first
    }
    
    public func objects<T: HandyJSON>(_ type:T.Type, predicate:NSPredicate) -> [T] {
        //无法使用format
        return self.db.prepare(type: type, sql: "SELECT rowid AS ssn_rowid, * FROM \(self.name) WHERE \(predicate.predicateFormat)", args: [])
    }
    
    public func objects<T: HandyJSON>(_ type:T.Type, conditions:[String:Binding?]) -> [T] {
        var wherestr = ""
        var upvalary:[Binding?] = []
        for (key,value) in conditions {
            if !wherestr.isEmpty {
                wherestr = wherestr + " AND "
            }
            wherestr = wherestr + "\(key) = ?"
            upvalary.append(value)
        }
        
        if wherestr.isEmpty {
            return self.db.prepare(type: type, sql: "SELECT rowid AS ssn_rowid, * FROM \(self.name)", args:[])
        } else {
            return self.db.prepare(type: type, sql: "SELECT rowid AS ssn_rowid, * FROM \(self.name) WHERE \(wherestr)", args: upvalary)
        }
    }

    public func truncate() {//清空表，请务必调用此方法，否则hook失效，并非sql语句“truncate table xxx”，实际执行delete语句，所以可以与其他方法一起在事务中使用
        self.db.execute("DELETE FROM \(self.name) WHERE rowid >= 0")
    }

    public func objectsCount() -> UInt64 {
        let value = self.db.prepare(sql: "SELECT count(1) AS count FROM \(self.name)", args: [])
        if let count = QValue(value).uint64 {
            return count
        }
        return 0
    }
    
    // MARK: 剥离存储columns
    private static func lastVersion(in tableDefinition:DBTableDefinition) -> UInt {
        var version:UInt = 0
        for template in tableDefinition.its.reversed() {
            if template.vs > version {
                version = template.vs
            }
        }
        return version
    }
    
    private static func columns(for version:UInt, in tableDefinition:DBTableDefinition) -> [DBColumn] {
        var cols:[DBColumn] = []
        for template in tableDefinition.its.reversed() {
            if template.vs == version {
                for col in template.cl {
                    let tableCol = DBColumn(definition: col)
                    cols.append(tableCol)
                }
            }
        }
        return cols
    }
    
    private var tableUniqueKey:String {
        return DBTable.tableUniqueKey(db: self._db, table: self.name)
    }
    
    fileprivate static func tableUniqueKey(db:DB?, table:String) -> String {
        if let db = db {
            return "\(db.scope)-\(table)"
        } else {
            return "-template-\(table)"
        }
    }
    
    public static func == (lhs: DBTable, rhs: DBTable) -> Bool {
        return lhs.tableUniqueKey == rhs.tableUniqueKey
    }
    
}

public enum DBColumnLevel:Int {
    case normal = 0,//"" 一般属性(可为空)
    notnull = 1,    //"NotNull" 一般属性(不允许为空)
    primary = 2    //"Primary" 主键（不允许为空）,多个时默认形成联合组件
}

public enum DBColumnIndex:Int {
    case nan = 0,//"" 不需要索引
    index = 1,    //"Index" 索引（不允许为空）
    unique = 2    //"Unique" 唯一索引（不允许为空）
}

public final class DBColumn {
    
    public var name:String { return _name }
    public var fill:String { return _fill } //默认填充值，default value
    public var mapping:String { return _mapping } //数据迁移时用原表字段名即可 `columnName` + 1)
    public var type:Int32 { return _type }
    public var level:DBColumnLevel { return _level }
    public var index:DBColumnIndex { return _index }
    
    public init(definition:DBTableColumnDefinition) {
        self._name = definition.name
        self._type = DBColumn.columnTypeValue(display:definition.type.uppercased())
        self._level = DBColumn.columnLevelValue(display:definition.level.uppercased())
        self._index = DBColumn.columnIndexValue(display:definition.index.uppercased())
        self._fill = definition.fill
        self._mapping = definition.mapping
    }
    
    public init(_ name:String, _ type:Int32, _ level:DBColumnLevel = .normal, _ index:DBColumnIndex = .nan,fill:String = "", mapping:String = "") {
        self._name = name
        self._type = type
        self._level = level
        self._index = index
        self._fill = fill
        self._mapping = mapping
    }
    
    
    public static func columnTypeValue(display:String) -> Int32 {
    if display == "INTEGER"
        || display == "INT"
        || display == "TINYINT"
        || display == "SMALLINT"
        || display == "MEDIUMINT"
        || display == "BIGINT"
        || display == "INT64"
        || display == "UNSIGNED BIG INT"
        || display == "INT2"
        || display == "INT8"
        || display == "BOOL" { return SQLITE_INTEGER }
    else if display == "REAL"
        || display == "DOUBLE"
        || display == "DOUBLE PRECISION"
        || display == "FLOAT" { return SQLITE_FLOAT }
    else if display == "TEXT"
        || display == "CHARACTER"
        || display == "VARCHAR"
        || display == "VARYING CHARACTER"
        || display == "NCHAR"
        || display == "NATIVE CHARACTER"
        || display == "NVARCHAR" { return SQLITE3_TEXT }//SQLITE_TEXT
    else if display == "BLOB" { return SQLITE_BLOB }
    else if display == "NULL" { return SQLITE_NULL }
    else { return SQLITE3_TEXT }
    }
    
    public static func columnLevelValue(display:String) -> DBColumnLevel {
        if display == "PRIMARY" { return .primary }
        else if display == "NOTNULL" { return .notnull }
        else { return .normal }
    }
    
    public static func columnIndexValue(display:String) -> DBColumnIndex {
        if display == "UNIQUE" { return .unique }
        else if display == "INDEX" { return .index }
        else { return .nan }
    }
    
    public static func columnTypeDisplay(value:Int32) -> String {
        if value == SQLITE_INTEGER { return "INTEGER" }
        else if value == SQLITE_FLOAT { return "REAL" }
        else if value == SQLITE_TEXT || value == SQLITE3_TEXT { return "TEXT" }
        else if value == SQLITE_BLOB { return "BLOB" }
        else if value == SQLITE_NULL { return "NULL" }
        else { return "TEXT" }
    }
    
    public static func primaries(columns:[DBColumn]) -> [String] {
        var cols:[String] = []
        for column in columns {
            if (column.level == .primary) {
                cols.append(column.name)
            }
        }
        return cols
    }
    
    public static func columnNames(columns:[DBColumn]) -> [String:DBColumn] {
        var cols:[String:DBColumn] = [:]
        for column in columns {
            cols[column.name] = column
        }
        return cols
    }
    
    private static func columnLevelDisplay(level:DBColumnLevel, supportPrimaryKey:Bool) -> String {
        switch level {
        case .normal:
            return ""
        case .notnull:
            return "NOT NULL"
        case .primary:
            if supportPrimaryKey {
                return "NOT NULL PRIMARY KEY"
            } else {
                return "NOT NULL"
            }
        }
    }
    
    public static func mutablePrimaryKeys(columns:[DBColumn]) -> String {
        var str = ""
        for column in columns {
            if column.level == .primary {
                if str.count > 0 {
                    str = str + ","
                }
                str = str + "\(column.name)"
            }
        }
        
        if str.count > 0 {
            return "PRIMARY KEY(\(str)) "
        } else {
            return ""
        }
    }

    // MARK: sql 支持
    //单纯数据创建
    public func sqlFragmentAtCreateTable(mutablePrimaryKeys:Bool) -> String {
        if _level == .notnull {
            return "\(_name) \(DBColumn.columnTypeDisplay(value: _type)) \(DBColumn.columnLevelDisplay(level: _level, supportPrimaryKey: !mutablePrimaryKeys)) "
        } else {
            return "\(_name) \(DBColumn.columnTypeDisplay(value: _type)) \(DBColumn.columnLevelDisplay(level: _level, supportPrimaryKey: !mutablePrimaryKeys)) DEFAULT \(self.fillString) "
        }
    }
    
    public func sqlCreateIndex(in tableName:String) -> String {
        if _index == .nan {
            return ""
        }
        let unique = self._index == .unique ? "UNIQUE" : ""
        return "CREATE \(unique) INDEX IF NOT EXISTS IDX_\(tableName)_\(_name) ON \(tableName) (\(_name))"
    }
    
    public func sqlFragmentMappingTable(oldExist:Bool) -> String {
        if !_mapping.isEmpty { //需要迁移,直接as就好了
            return "( \(_mapping) ) AS \(_name)"
        } else {
            if oldExist {
                return "\(_name)"
            }
            else {
                return "( \(fillString) ) AS \(_name)"
            }
        }
    }
    
    public var fillString:String {
        if DBColumn.columnTypeDisplay(value: _type) == "TEXT" {
            if _fill.isEmpty || _fill == "NULL" {
                return "NULL"
            } else {
                return "'\(_fill)'"
            }
        } else {
            if _fill.isEmpty {
                return "0"
            } else {
                return _fill
            }
        }
    }


    //MARK: creat table
    public static func sqlCreateTable(columns:[DBColumn],in table:String) -> String {
        //直接创建数据表
        var sql = "CREATE TABLE IF NOT EXISTS \(table) ("
        
        let primaryKeys = DBColumn.mutablePrimaryKeys(columns:columns)
        let isMutable = !primaryKeys.isEmpty
        
        
        var isFirst = true
        for column in columns {
            if (!isFirst) {
                sql = sql + ","
            } else {
                isFirst = false
            }
            sql = sql + column.sqlFragmentAtCreateTable(mutablePrimaryKeys:isMutable)
        }
        
        //加上联合主键
        if (isMutable) {
            sql = sql + ",\(primaryKeys)"
        }
        
        sql = sql + ")"
        
        return sql
    }
    
    public static func sqlCreateIndex(columns:[DBColumn],in table:String) -> [String] {
        var sqls:[String] = []
        for column in columns {
            //索引sql
            let sql = column.sqlCreateIndex(in: table)
            if !sql.isEmpty {
                sqls.append(sql)
            }
        }
        return sqls
    }
    
    public func isEqualTo(column:DBColumn,ignore mapping:Bool) -> Bool {
        if _name == column._name
            && _fill == column._fill
            && _type == column.type
            && _level == column.level
            && _index == column.index {
            if (mapping) {
                return true
            } else {
                return _mapping == column._mapping
            }
        }
        return false
    }
    
    public static func isSameTable(from:[DBColumn],to:[DBColumn],check mapping:Bool = false) -> Bool {
        if from.count != to.count {
            return false
        }
        
        var fromDic:[String:DBColumn] = [:]
        var fromSet:[String] = []
        for col in from {
            fromSet.append(col.name)
            fromDic[col.name] = col
        }
        
        var change = false
        for col in to {
            let fcol = fromDic[col.name]
            if fcol == nil || !fcol!.isEqualTo(column: col, ignore: true) {
                change = true
                break
            } else if mapping && !col.mapping.isEmpty {
                change = true
                break
            }
        }
        return change
    }
    
    //数据库升级控制
    public static func mapping(table:String, fromColumns:[DBColumn], toColumns:[DBColumn], last:Bool) -> [String] {
        
        var toDic:[String:DBColumn] = [:]//用于无序分析表样式，前后两张表如果
        var fromSet:[String] = []
        
        for col in toColumns {
            toDic[col.name] = col
        }
        
        for col in fromColumns {
            fromSet.append(col.name)
        }
        
        var sqls:[String] = []
        
        //属性没有发生任何变化，此时只需要关注值的变化 //说明连数据迁移项也没有，数据表不需要任何改变
        if DBColumn.isSameTable(from: fromColumns, to: toColumns, check: true) {
            return sqls
        }
        
        // 1 改变原来表名字
        sqls.append("ALTER TABLE \(table) RENAME TO __temp__\(table)")
        
        // 2 创建新的表
        sqls.append(DBColumn.sqlCreateTable(columns: toColumns, in: table))
        
        // 3 导入数据（create table as 虽然速度快，但是表字段定义类型模糊【无类型】，主键索引都无法描述）
        var mappingSql = "INSERT INTO \(table) SELECT "
        var isFirst = true
        for col in toColumns {
            if (isFirst) {
                isFirst = false
            } else {
                mappingSql = mappingSql + ","
            }
            mappingSql = mappingSql + col.sqlFragmentMappingTable(oldExist: fromSet.contains(col.name))
        }
        mappingSql = mappingSql + " FROM __temp__\(table)"
        sqls.append(mappingSql)
        
        // 4 删除临时表
        sqls.append("DROP TABLE __temp__\(table)")
        
        // 5 重新创建索引(最后一次创建索引，索引创建消耗比较大)
        if (last) {
            let indexSqls = DBColumn.sqlCreateIndex(columns: toColumns, in: table)
            if indexSqls.count > 0 {
                sqls.append(contentsOf: indexSqls)
            }
        }
        
        /*
         另外，如果遇到复杂的修改操作，比如在修改的同时，需要进行数据的转移，那么可以采取在一个事务中执行如下语句来实现修改表的需求。
         　　　　1. 将表名改为临时表
         ALTER TABLE Subscription RENAME TO __temp__Subscription;
         　　　　2. 创建新表
         CREATE TABLE Subscription (OrderId VARCHAR(32) PRIMARY KEY ,UserName VARCHAR(32) NOT NULL ,ProductId VARCHAR(16)
         NOT NULL);
         
         //CREATE TABLE lw_ext_friend AS SELECT userId,name,(iSSNTar+1)*3 AS starOne FROM lw_friend
         
         //CREATE TABLE lw_friend_ext AS SELECT userId,name,'' as dddd,0 as  tttt FROM lw_friend
         
         3. 导入数据
         INSERT INTO Subscription SELECT OrderId, “”, ProductId FROM __temp__Subscription;
         　　　　或者
         INSERT INTO Subscription() SELECT OrderId, “”, ProductId FROM __temp__Subscription;
         　　　　* 注意 双引号”” 是用来补充原来不存在的数据的
         
         4. 删除临时表
         DROP TABLE __temp__Subscription;
         
         　　　　通过以上四个步骤，就可以完成旧数据库结构向新数据库结构的迁移，并且其中还可以保证数据不会应为升级而流失。
         　　　　当然，如果遇到减少字段的情况，也可以通过创建临时表的方式来实现。
         */
        
        return sqls;
    }
    
    
    
    private var _name = ""
    private var _fill = ""
    private var _mapping = ""
    private var _type:Int32 = 0
    private var _level:DBColumnLevel = .normal
    private var _index:DBColumnIndex = .nan
}

//extension UInt : Number, Value {
//
//    public static var declaredDatatype = Int64.declaredDatatype
//
//    public static func fromDatatypeValue(_ datatypeValue: Int64) -> UInt {
//        return UInt(datatypeValue)
//    }
//
//    public var datatypeValue: Int64 {
//        return Int64(self)
//    }
//}

extension DBTable {
    private static func validFieldValue(obj:HandyJSON, column dictionary:[String:DBColumn]) -> [String:Binding] {
        var result:[String:Binding] = [:]
        if let dict = obj.toJSON() {
            for (key, value) in dict {
                //仅仅处理包含的字段
                if let col = dictionary[key] {
                    //过滤非法的主键字段
                    if col.level == .primary {
                        if col.type == SQLITE_INTEGER || col.type == SQLITE_FLOAT {
                            if let v = QValue("\(value)").int, v == 0 { continue }
                        } else if "\(value)".isEmpty { continue }
                    }
                    
                    var v:Binding? = nil
                    if col.type == SQLITE_INTEGER { v = QValue("\(value)").int64 }
                    else if col.type == SQLITE_FLOAT { v = QValue("\(value)").double }
                    else { v = "\(value)" }
                    if let v = v {
                        result[key] = v
                    }
                }
            }
        }
        return result
    }
    
    //MARK: 日志表操作
    private static func checkCreateTableLog(db:DB) {
        db.execute("CREATE TABLE IF NOT EXISTS ssn_db_tb_log (name TEXT, value INTEGER, PRIMARY KEY(name))")
    }
    
    private static func version(db:DB, for table:String) -> UInt {
        let result = db.prepare(sql: "SELECT value FROM ssn_db_tb_log WHERE name = ?", args: [table])
        if let value = QValue(result).uint {
            return value
        }
        return 0
    }
    
    private static func update(db:DB, version:UInt, for table:String) {
        if version > 0 {
            //采用sql0将造成rowid更新，实际操作是delete and insert
            let sql1 = "UPDATE ssn_db_tb_log SET value = ? WHERE name = ?"
            let sql2 = "INSERT INTO ssn_db_tb_log (name,value) VALUES(?,?)"
            db.transaction(block: { (db) in
                db.prepare(sql: sql1, args: [Int(version),table])
                db.prepare(sql: sql2, args: [table,Int(version)])
            })
        } else {
            removeVersion(db:db, for:table)
        }
    }
    
    private static func removeVersion(db:DB, for table:String) {
        db.prepare(sql: "DELETE FROM ssn_db_tb_log WHERE name = ?", args: [table])
    }
    
    private static func upgrade(db:DB, table:String, table definition:DBTableDefinition) {
        let currentVersion = DBTable.version(db:db ,for:table)
        let lastVersion = definition.lastVersion()
        var status:DBTableStatus = .none
        if (currentVersion == 0) { //还没有建标
            status = .none
        } else if (currentVersion < lastVersion) { //待更新
            status = .update
        } else {
            status = .ok
        }
        
        //已经创建表了
        if status == .ok {
            return
        }
        
        //需要更新标信息存储
        db.sync(block: { (db) in
            if currentVersion == 0 {
                let cols = definition.columns(for: lastVersion)
                DBTable.create(db: db, table: table, columns: cols)
            } else {
                for vs in currentVersion..<lastVersion {
                    let fcols = definition.columns(for: vs)
                    let tcols = definition.columns(for: vs + 1)
                    DBTable.maping(db: db, table: table, fromColumns: fcols, toColumns: tcols, last: vs + 1 == lastVersion)
                }
            }
            
            //最后更新表记录
            DBTable.update(db:db, version: lastVersion, for: table)
        })
        
    }
    
    //MARK: 表创建于更新实现
    private static func maping(db:DB, table:String, fromColumns:[DBColumn], toColumns:[DBColumn], last:Bool) {
        let sqls = DBColumn.mapping(table: table, fromColumns: fromColumns, toColumns: toColumns, last: last)
        var sql = ""
        for str in sqls {
            sql = sql + str + ";"
        }
        db.execute(sql)
    }
    
    private static func create(db:DB, table:String, columns:[DBColumn])
    {
        var sql = DBColumn.sqlCreateTable(columns: columns, in: table) + ";"
        let sqls = DBColumn.sqlCreateIndex(columns: columns, in: table)
        for str in sqls {
            sql = sql + str + ";"
        }
        db.execute(sql)
    }
    
    
}

// MARK: factory方法
extension DBTable {
    
    public static func table(db:DB? = nil, name:String, template:String = "") -> DBTable {
        let key = DBTable.tableUniqueKey(db: db, table: name)
        var info:[String:Any] = [:]
        info["DB"] = db
        info["name"] = name
        info["template"] = template
        return _pool.get(key, info: info)!
    }
    
    private static let _pool = RigidCache<DBTable>({ (scope, info) -> DBTable in
        let db:DB? = info?["DB"] as? DB
        let name:String? = info?["name"] as? String
        let template:String? = info?["template"] as? String
        var templateTable:DBTable = DBTable()
        if let db = db, let name = name, !name.isEmpty {
            if let template = template, !template.isEmpty {
                if let url = Bundle.main.url(forResource: template, withExtension: "json") {
                    templateTable = DBTable(tableJSONDescription: url)
                }
                return DBTable(db: db, template: templateTable, name: name)
            } else {
                if let url = Bundle.main.url(forResource: name, withExtension: "json") {
                    return DBTable(db: db, tableJSONDescription: url)
                }
            }
        }
        return templateTable
    })
}


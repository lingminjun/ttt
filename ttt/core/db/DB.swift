//
//  DB.swift
//  ttt
//
//  Created by lingminjun on 2018/7/6.
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

import SQLite.Swift

//直接采用HandyJSON内存赋值模型（不重复造轮子）
import HandyJSON

//通知定义
let SQLITE_UPDATED_NOTICE = NSNotification.Name(rawValue:"SQLite.Database.Data.Updated")
let SQLITE_COMMIT_NOTICE = NSNotification.Name(rawValue:"SQLite.Database.Commit")
let SQLITE_ROLLBACK_NOTICE = NSNotification.Name(rawValue:"SQLite.Database.Rollback")

let SQLITE_TABLE_KEY = "Table"
let SQLITE_OPERATION_KEY = "Operation"
let SQLITE_ROW_ID_KEY = "RowId"

//数据库（单链接）包装类
public final class DB : NSObject {
    
    public var scope:String {
        return _scope
    }
    
    private var _cnnt:Connection!
    private var _scope = ""
    private var _path = ""
    
    public init(_ scope:String = "default") {
        super.init()
        self._scope = scope
        self._path = DB.path(for: scope)
        print("open:\(_path)")
        if let cn = try? Connection(self._path) {
            self._cnnt = cn
        } else {
            if !checkDBFile() {
                fatalError("数据库无法正常创建，请检查输入参数")
            }
        }
        
        //注册更新通知
        self._cnnt.updateHook { [weak self] (opt, dbName, tbName, rowId) in
            if let sself = self {
                //主线程回调
                let dict:[String : Any] = [SQLITE_OPERATION_KEY:opt,SQLITE_TABLE_KEY:tbName,SQLITE_ROW_ID_KEY:rowId]
                // 防止hook同来自sqlite事务的同一个栈，尽量不要终止原有事务操作，故将通知转到另一个loop source
                sself.performSelector(onMainThread: #selector(DB.hook(dict:)), with: dict, waitUntilDone: false)
//                NotificationCenter.default.post(name: SQLITE_UPDATED_NOTICE, object: sself, userInfo: dict)
            }
        }
        
    }
    
    deinit {
        //源码没有释放
        self._cnnt.updateHook(nil)
    }
    
    @objc fileprivate func hook(dict:[String : Any]) {
        NotificationCenter.default.post(name: SQLITE_UPDATED_NOTICE, object: self, userInfo: dict)
    }
    
    // MARK: sql method
    public func execute(_ sql:String) {//错误直接忽略
        print("execute:\(sql)")
        do {
            try self._cnnt.execute(sql)
        } catch {
            print("error:\(error)")
        }
    }
    
    //请使用execute来执行命令，若查询数据，请使用 objects:sql:args:方法
    @discardableResult
    public func prepare(sql:String, args: [Binding?]) -> String {
        print("prepare:\(sql)")
        do {
            let list = try self._cnnt.prepare(sql, args)
            for data in list {
                return "\(String(describing: data[0]))"
            }
        } catch {
            print("error:\(error)")
        }
        return ""
    }

    // aclass传入NULL时默认用NSDictionary代替，当执行单纯的sql时，忽略aclass，返回值将为nil,为了防止sql注入，请输入参数
    public func prepare<T: HandyJSON>(type:T.Type, sql:String, args: [Binding?]) -> [T] {
        print("prepare:\(sql)")
        var result:[T] = []
        do {
            let list = try self._cnnt.prepare(sql, args)
            let columnCount = list.columnCount
            let columnNames = list.columnNames
            for data in list {
                var dict:[String:Any] = [:]
                for idx in 0..<columnCount {
                    dict[columnNames[idx]] = data[idx]
                }
                if let obj = T.deserialize(from: dict) {
                    result.append(obj)
                }
            }
        } catch {
            print("error:\(error)")
        }
        return result
    }
    
    //执行事务，在arc中请注意传入strong参数，确保操作完成，防止循环引用
    public func transaction(block:(_ db:DB) -> Void) {
        do {
            try self._cnnt.transaction { [weak self] in
                if let db = self {
                    block(db)
                }
            }
        } catch {
            print("error:\(error)")
        }
    }    

//    #pragma attach other database completed arduous task
//    /**
//     @brief 创建一个临时库来执行一项艰巨的任务，这里建议是一些非常耗时的任务，然后关联两个数据库，进行数据库关联操作，请不要随意使用，注意保持一个attachDatabase独立
//     @param attachDatabase 临时库的名字，目录在主库目录下
//     @param arduousBlock   艰巨任务执行block，临时库不建议应用出block，每次操作完他将关闭，不然后面的attach 可能失效，此block在非主库线程中
//     @param attachBlock    最后关联动作执行，此block在主库线程中执行
//
//     使用场景说明：比如有一项非常艰巨的任务，大批量的数据导入，如果直接在主库线程中执行，非常占用时间，导致其他模块阻塞，你可以采用临时库来完成
//     sql:[db executeSql:@"INSERT OR IGNORE INTO table_name SELECT * FROM attach_db.table_name"];
//     */
//    - (void)addAttachDatabase:(NSString *)attachDatabase arduousBlock:(void (^)(SSNDB *attachDB))arduousBlock attachBlock:(void (^)(SSNDB *db, NSString *attachDatabase))attachBlock;
//
//    /**
//     @brief 移除临时表
//     @param attachDatabase 临时库的名字，目录在主库目录下
//     */
//    - (void)removeAttachDatabase:(NSString *)attachDatabase;//删除临时数据库
    
    private static func path(for scope:String, filename:String = "core.db") -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        //创建目录
        let dir = paths[0].appending("/\(scope)")
        let manager = FileManager()
        try? manager.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        
        let path = paths[0].appending("/\(scope)/\(filename)")
        return path
    }

    private func checkDBFile() -> Bool {
        //再来一遍
        if let cn = try? Connection(self._path) {
            self._cnnt = cn
            return true
        }
        
        let manager = FileManager()
        //文件存在，尝试第二次打开
        if (!manager.fileExists(atPath: self._path)) {
            return false
        }
        
        try? manager.removeItem(atPath: self._path)
        
        //重新创建新的库文件
        if let cn = try? Connection(self._path) {
            self._cnnt = cn
            return true
        }
        return false
    }
    
    public static func == (lhs: DB, rhs: DB) -> Bool {
        return lhs._scope == rhs._scope
    }
}

// MARK: DB Pool (Factory)
public extension DB {
    public static func db(with scope:String) -> DB {
        return _pool.get(scope)!
    }
    
    private static let _pool = RigidCache<DB>({ (scope, info) -> DB in
        return DB(scope)
    })
}



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
    
    /// An SQL operation passed to update callbacks.
    public enum Operation {
        
        /// An INSERT operation.
        case insert
        
        /// An UPDATE operation.
        case update
        
        /// A DELETE operation.
        case delete
        
        fileprivate init(rawValue:Int32) {
            switch rawValue {
            case SQLITE_INSERT:
                self = .insert
            case SQLITE_UPDATE:
                self = .update
            case SQLITE_DELETE:
                self = .delete
            default:
                fatalError("unhandled operation code: \(rawValue)")
            }
        }
    }
    
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
                if let value = data[0] {
                    return "\(String(describing: value))"
                }
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
    
    /// 执行多项DDL语句
    public func sync(block: (_ db:DB) -> Void) {
        self._cnnt.sync({ [weak self] () -> Void in
            if let db = self {
                block(db)
            }
        })
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

// let SQLITE_STATIC = unsafeBitCast(0, sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// A connection to SQLite.
public final class Connection {
    
    /// The location of a SQLite database.
    public enum Location {
        
        /// An in-memory database (equivalent to `.uri(":memory:")`).
        ///
        /// See: <https://www.sqlite.org/inmemorydb.html#sharedmemdb>
        case inMemory
        
        /// A temporary, file-backed database (equivalent to `.uri("")`).
        ///
        /// See: <https://www.sqlite.org/inmemorydb.html#temp_db>
        case temporary
        
        /// A database located at the given URI filename (or path).
        ///
        /// See: <https://www.sqlite.org/uri.html>
        ///
        /// - Parameter filename: A URI filename
        case uri(String)
    }
    
    public var handle: OpaquePointer { return _handle! }
    
    fileprivate var _handle: OpaquePointer? = nil
    
    /// Initializes a new SQLite connection.
    ///
    /// - Parameters:
    ///
    ///   - location: The location of the database. Creates a new database if it
    ///     doesn’t already exist (unless in read-only mode).
    ///
    ///     Default: `.inMemory`.
    ///
    ///   - readonly: Whether or not to open the database in a read-only state.
    ///
    ///     Default: `false`.
    ///
    /// - Returns: A new database connection.
    public init(_ location: Location = .inMemory, readonly: Bool = false, mutex:Int32 = SQLITE_OPEN_NOMUTEX) throws {
        let flags = readonly ? SQLITE_OPEN_READONLY : SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE
        try check(sqlite3_open_v2(location.description, &_handle, flags | mutex, nil))
        queue.setSpecific(key: Connection.queueKey, value: queueContext)
    }
    
    /// Initializes a new connection to a database.
    ///
    /// - Parameters:
    ///
    ///   - filename: The location of the database. Creates a new database if
    ///     it doesn’t already exist (unless in read-only mode).
    ///
    ///   - readonly: Whether or not to open the database in a read-only state.
    ///
    ///     Default: `false`.
    ///
    /// - Throws: `Result.Error` iff a connection cannot be established.
    ///
    /// - Returns: A new database connection.
    public convenience init(_ filename: String, readonly: Bool = false) throws {
        try self.init(.uri(filename), readonly: readonly)
    }
    
    deinit {
        if let handle = _handle {
            sqlite3_close(handle)
        }
    }
    
    // MARK: -
    
    /// Whether or not the database was opened in a read-only state.
    public var readonly: Bool { return sqlite3_db_readonly(handle, nil) == 1 }
    
    /// The last rowid inserted into the database via this connection.
    public var lastInsertRowid: Int64 {
        return sqlite3_last_insert_rowid(handle)
    }
    
    /// The last number of changes (inserts, updates, or deletes) made to the
    /// database via this connection.
    public var changes: Int {
        return Int(sqlite3_changes(handle))
    }
    
    /// The total number of changes (inserts, updates, or deletes) made to the
    /// database via this connection.
    public var totalChanges: Int {
        return Int(sqlite3_total_changes(handle))
    }
    
    // MARK: - Execute
    
    /// Executes a batch of SQL statements.
    ///
    /// - Parameter SQL: A batch of zero or more semicolon-separated SQL
    ///   statements.
    ///
    /// - Throws: `Result.Error` if query execution fails.
    public func execute(_ SQL: String) throws {
        _ = try sync { try self.check(sqlite3_exec(self.handle, SQL, nil, nil, nil)) }
    }
    
    // MARK: - Prepare
    
    /// Prepares a single SQL statement (with optional parameter bindings).
    ///
    /// - Parameters:
    ///
    ///   - statement: A single SQL statement.
    ///
    ///   - bindings: A list of parameters to bind to the statement.
    ///
    /// - Returns: A prepared statement.
    public func prepare(_ statement: String, _ bindings: Binding?...) throws -> Statement {
        if !bindings.isEmpty { return try prepare(statement, bindings) }
        return try Statement(self, statement)
    }
    
    /// Prepares a single SQL statement and binds parameters to it.
    ///
    /// - Parameters:
    ///
    ///   - statement: A single SQL statement.
    ///
    ///   - bindings: A list of parameters to bind to the statement.
    ///
    /// - Returns: A prepared statement.
    public func prepare(_ statement: String, _ bindings: [Binding?]) throws -> Statement {
        return try prepare(statement).bind(bindings)
    }
    
    /// Prepares a single SQL statement and binds parameters to it.
    ///
    /// - Parameters:
    ///
    ///   - statement: A single SQL statement.
    ///
    ///   - bindings: A dictionary of named parameters to bind to the statement.
    ///
    /// - Returns: A prepared statement.
    public func prepare(_ statement: String, _ bindings: [String: Binding?]) throws -> Statement {
        return try prepare(statement).bind(bindings)
    }
    
    // MARK: - Run
    
    /// Runs a single SQL statement (with optional parameter bindings).
    ///
    /// - Parameters:
    ///
    ///   - statement: A single SQL statement.
    ///
    ///   - bindings: A list of parameters to bind to the statement.
    ///
    /// - Throws: `Result.Error` if query execution fails.
    ///
    /// - Returns: The statement.
    @discardableResult public func run(_ statement: String, _ bindings: Binding?...) throws -> Statement {
        return try run(statement, bindings)
    }
    
    /// Prepares, binds, and runs a single SQL statement.
    ///
    /// - Parameters:
    ///
    ///   - statement: A single SQL statement.
    ///
    ///   - bindings: A list of parameters to bind to the statement.
    ///
    /// - Throws: `Result.Error` if query execution fails.
    ///
    /// - Returns: The statement.
    @discardableResult public func run(_ statement: String, _ bindings: [Binding?]) throws -> Statement {
        return try prepare(statement).run(bindings)
    }
    
    /// Prepares, binds, and runs a single SQL statement.
    ///
    /// - Parameters:
    ///
    ///   - statement: A single SQL statement.
    ///
    ///   - bindings: A dictionary of named parameters to bind to the statement.
    ///
    /// - Throws: `Result.Error` if query execution fails.
    ///
    /// - Returns: The statement.
    @discardableResult public func run(_ statement: String, _ bindings: [String: Binding?]) throws -> Statement {
        return try prepare(statement).run(bindings)
    }
    
    // MARK: - Scalar
    
    /// Runs a single SQL statement (with optional parameter bindings),
    /// returning the first value of the first row.
    ///
    /// - Parameters:
    ///
    ///   - statement: A single SQL statement.
    ///
    ///   - bindings: A list of parameters to bind to the statement.
    ///
    /// - Returns: The first value of the first row returned.
    public func scalar(_ statement: String, _ bindings: Binding?...) throws -> Binding? {
        return try scalar(statement, bindings)
    }
    
    /// Runs a single SQL statement (with optional parameter bindings),
    /// returning the first value of the first row.
    ///
    /// - Parameters:
    ///
    ///   - statement: A single SQL statement.
    ///
    ///   - bindings: A list of parameters to bind to the statement.
    ///
    /// - Returns: The first value of the first row returned.
    public func scalar(_ statement: String, _ bindings: [Binding?]) throws -> Binding? {
        return try prepare(statement).scalar(bindings)
    }
    
    /// Runs a single SQL statement (with optional parameter bindings),
    /// returning the first value of the first row.
    ///
    /// - Parameters:
    ///
    ///   - statement: A single SQL statement.
    ///
    ///   - bindings: A dictionary of named parameters to bind to the statement.
    ///
    /// - Returns: The first value of the first row returned.
    public func scalar(_ statement: String, _ bindings: [String: Binding?]) throws -> Binding? {
        return try prepare(statement).scalar(bindings)
    }
    
    // MARK: - Transactions
    
    /// The mode in which a transaction acquires a lock.
    public enum TransactionMode : String {
        
        /// Defers locking the database till the first read/write executes.
        case deferred = "DEFERRED"
        
        /// Immediately acquires a reserved lock on the database.
        case immediate = "IMMEDIATE"
        
        /// Immediately acquires an exclusive lock on all databases.
        case exclusive = "EXCLUSIVE"
        
    }
    
    // TODO: Consider not requiring a throw to roll back?
    /// Runs a transaction with the given mode.
    ///
    /// - Note: Transactions cannot be nested. To nest transactions, see
    ///   `savepoint()`, instead.
    ///
    /// - Parameters:
    ///
    ///   - mode: The mode in which a transaction acquires a lock.
    ///
    ///     Default: `.deferred`
    ///
    ///   - block: A closure to run SQL statements within the transaction.
    ///     The transaction will be committed when the block returns. The block
    ///     must throw to roll the transaction back.
    ///
    /// - Throws: `Result.Error`, and rethrows.
    public func transaction(_ mode: TransactionMode = .deferred, block: () throws -> Void) throws {
        try transaction("BEGIN \(mode.rawValue) TRANSACTION", block, "COMMIT TRANSACTION", or: "ROLLBACK TRANSACTION")
    }
    
    // TODO: Consider not requiring a throw to roll back?
    // TODO: Consider removing ability to set a name?
    /// Runs a transaction with the given savepoint name (if omitted, it will
    /// generate a UUID).
    ///
    /// - SeeAlso: `transaction()`.
    ///
    /// - Parameters:
    ///
    ///   - savepointName: A unique identifier for the savepoint (optional).
    ///
    ///   - block: A closure to run SQL statements within the transaction.
    ///     The savepoint will be released (committed) when the block returns.
    ///     The block must throw to roll the savepoint back.
    ///
    /// - Throws: `SQLite.Result.Error`, and rethrows.
    public func savepoint(_ name: String = UUID().uuidString, block: () throws -> Void) throws {
        let name = quote(name,"'")
        let savepoint = "SAVEPOINT \(name)"
        
        try transaction(savepoint, block, "RELEASE \(savepoint)", or: "ROLLBACK TO \(savepoint)")
    }
    
    func quote(_ str:String , _ mark: Character = "\"") -> String {
        let escaped = str.reduce("") { string, character in
            string + (character == mark ? "\(mark)\(mark)" : "\(character)")
        }
        return "\(mark)\(escaped)\(mark)"
    }
    
    fileprivate func transaction(_ begin: String, _ block: () throws -> Void, _ commit: String, or rollback: String) throws {
        return try sync {
            try self.run(begin)
            do {
                try block()
                try self.run(commit)
            } catch {
                try self.run(rollback)
                throw error
            }
        }
    }
    
    /// Interrupts any long-running queries.
    public func interrupt() {
        sqlite3_interrupt(handle)
    }
    
    // MARK: - Handlers
    
    /// The number of seconds a connection will attempt to retry a statement
    /// after encountering a busy signal (lock).
    public var busyTimeout: Double = 0 {
        didSet {
            sqlite3_busy_timeout(handle, Int32(busyTimeout * 1_000))
        }
    }
    
    /// Sets a handler to call after encountering a busy signal (lock).
    ///
    /// - Parameter callback: This block is executed during a lock in which a
    ///   busy error would otherwise be returned. It’s passed the number of
    ///   times it’s been called for this lock. If it returns `true`, it will
    ///   try again. If it returns `false`, no further attempts will be made.
    public func busyHandler(_ callback: ((_ tries: Int) -> Bool)?) {
        guard let callback = callback else {
            sqlite3_busy_handler(handle, nil, nil)
            busyHandler = nil
            return
        }
        
        let box: BusyHandler = { callback(Int($0)) ? 1 : 0 }
        sqlite3_busy_handler(handle, { callback, tries in
            unsafeBitCast(callback, to: BusyHandler.self)(tries)
        }, unsafeBitCast(box, to: UnsafeMutableRawPointer.self))
        busyHandler = box
    }
    fileprivate typealias BusyHandler = @convention(block) (Int32) -> Int32
    fileprivate var busyHandler: BusyHandler?
    
    /// Sets a handler to call when a statement is executed with the compiled
    /// SQL.
    ///
    /// - Parameter callback: This block is invoked when a statement is executed
    ///   with the compiled SQL as its argument.
    ///
    ///       db.trace { SQL in print(SQL) }
    public func trace(_ callback: ((String) -> Void)?) {
        #if SQLITE_SWIFT_SQLCIPHER || os(Linux)
        trace_v1(callback)
        #else
        if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
            trace_v2(callback)
        } else {
            trace_v1(callback)
        }
        #endif
    }
    
    fileprivate func trace_v1(_ callback: ((String) -> Void)?) {
        guard let callback = callback else {
            sqlite3_trace(handle, nil /* xCallback */, nil /* pCtx */)
            trace = nil
            return
        }
        let box: Trace = { (pointer: UnsafeRawPointer) in
            callback(String(cString: pointer.assumingMemoryBound(to: UInt8.self)))
        }
        sqlite3_trace(handle,
                      {
                        (C: UnsafeMutableRawPointer?, SQL: UnsafePointer<Int8>?) in
                        if let C = C, let SQL = SQL {
                            unsafeBitCast(C, to: Trace.self)(SQL)
                        }
        },
                      unsafeBitCast(box, to: UnsafeMutableRawPointer.self)
        )
        trace = box
    }
    
    
    
    
    fileprivate typealias Trace = @convention(block) (UnsafeRawPointer) -> Void
    fileprivate var trace: Trace?
    
    /// Registers a callback to be invoked whenever a row is inserted, updated,
    /// or deleted in a rowid table.
    ///
    /// - Parameter callback: A callback invoked with the `Operation` (one of
    ///   `.Insert`, `.Update`, or `.Delete`), database name, table name, and
    ///   rowid.
    public func updateHook(_ callback: ((_ operation: DB.Operation, _ db: String, _ table: String, _ rowid: Int64) -> Void)?) {
        guard let callback = callback else {
            sqlite3_update_hook(handle, nil, nil)
            updateHook = nil
            return
        }
        
        let box: UpdateHook = {
            callback(
                DB.Operation(rawValue: $0),
                String(cString: $1),
                String(cString: $2),
                $3
            )
        }
        sqlite3_update_hook(handle, { callback, operation, db, table, rowid in
            unsafeBitCast(callback, to: UpdateHook.self)(operation, db!, table!, rowid)
        }, unsafeBitCast(box, to: UnsafeMutableRawPointer.self))
        updateHook = box
    }
    fileprivate typealias UpdateHook = @convention(block) (Int32, UnsafePointer<Int8>, UnsafePointer<Int8>, Int64) -> Void
    fileprivate var updateHook: UpdateHook?
    
    /// Registers a callback to be invoked whenever a transaction is committed.
    ///
    /// - Parameter callback: A callback invoked whenever a transaction is
    ///   committed. If this callback throws, the transaction will be rolled
    ///   back.
    public func commitHook(_ callback: (() throws -> Void)?) {
        guard let callback = callback else {
            sqlite3_commit_hook(handle, nil, nil)
            commitHook = nil
            return
        }
        
        let box: CommitHook = {
            do {
                try callback()
            } catch {
                return 1
            }
            return 0
        }
        sqlite3_commit_hook(handle, { callback in
            unsafeBitCast(callback, to: CommitHook.self)()
        }, unsafeBitCast(box, to: UnsafeMutableRawPointer.self))
        commitHook = box
    }
    fileprivate typealias CommitHook = @convention(block) () -> Int32
    fileprivate var commitHook: CommitHook?
    
    /// Registers a callback to be invoked whenever a transaction rolls back.
    ///
    /// - Parameter callback: A callback invoked when a transaction is rolled
    ///   back.
    public func rollbackHook(_ callback: (() -> Void)?) {
        guard let callback = callback else {
            sqlite3_rollback_hook(handle, nil, nil)
            rollbackHook = nil
            return
        }
        
        let box: RollbackHook = { callback() }
        sqlite3_rollback_hook(handle, { callback in
            unsafeBitCast(callback, to: RollbackHook.self)()
        }, unsafeBitCast(box, to: UnsafeMutableRawPointer.self))
        rollbackHook = box
    }
    fileprivate typealias RollbackHook = @convention(block) () -> Void
    fileprivate var rollbackHook: RollbackHook?
    
    /// Creates or redefines a custom SQL function.
    ///
    /// - Parameters:
    ///
    ///   - function: The name of the function to create or redefine.
    ///
    ///   - argumentCount: The number of arguments that the function takes. If
    ///     `nil`, the function may take any number of arguments.
    ///
    ///     Default: `nil`
    ///
    ///   - deterministic: Whether or not the function is deterministic (_i.e._
    ///     the function always returns the same result for a given input).
    ///
    ///     Default: `false`
    ///
    ///   - block: A block of code to run when the function is called. The block
    ///     is called with an array of raw SQL values mapped to the function’s
    ///     parameters and should return a raw SQL value (or nil).
    public func createFunction(_ function: String, argumentCount: UInt? = nil, deterministic: Bool = false, _ block: @escaping (_ args: [Binding?]) -> Binding?) {
        let argc = argumentCount.map { Int($0) } ?? -1
        let box: Function = { context, argc, argv in
            let arguments: [Binding?] = (0..<Int(argc)).map { idx in
                let value = argv![idx]
                switch sqlite3_value_type(value) {
                case SQLITE_BLOB:
                    return Blob(bytes: sqlite3_value_blob(value), length: Int(sqlite3_value_bytes(value)))
                case SQLITE_FLOAT:
                    return sqlite3_value_double(value)
                case SQLITE_INTEGER:
                    return sqlite3_value_int64(value)
                case SQLITE_NULL:
                    return nil
                case SQLITE_TEXT:
                    return String(cString: UnsafePointer(sqlite3_value_text(value)))
                case let type:
                    fatalError("unsupported value type: \(type)")
                }
            }
            let result = block(arguments)
            if let result = result as? Blob {
                sqlite3_result_blob(context, result.bytes, Int32(result.bytes.count), nil)
            } else if let result = result as? Double {
                sqlite3_result_double(context, result)
            } else if let result = result as? Int64 {
                sqlite3_result_int64(context, result)
            } else if let result = result as? String {
                sqlite3_result_text(context, result, Int32(result.count), SQLITE_TRANSIENT)
            } else if result == nil {
                sqlite3_result_null(context)
            } else {
                fatalError("unsupported result type: \(String(describing: result))")
            }
        }
        var flags = SQLITE_UTF8
        #if !os(Linux)
        if deterministic {
            flags |= SQLITE_DETERMINISTIC
        }
        #endif
        sqlite3_create_function_v2(handle, function, Int32(argc), flags, unsafeBitCast(box, to: UnsafeMutableRawPointer.self), { context, argc, value in
            let function = unsafeBitCast(sqlite3_user_data(context), to: Function.self)
            function(context, argc, value)
        }, nil, nil, nil)
        if functions[function] == nil { self.functions[function] = [:] }
        functions[function]?[argc] = box
    }
    fileprivate typealias Function = @convention(block) (OpaquePointer?, Int32, UnsafeMutablePointer<OpaquePointer?>?) -> Void
    fileprivate var functions = [String: [Int: Function]]()
    
    /// Defines a new collating sequence.
    ///
    /// - Parameters:
    ///
    ///   - collation: The name of the collation added.
    ///
    ///   - block: A collation function that takes two strings and returns the
    ///     comparison result.
    public func createCollation(_ collation: String, _ block: @escaping (_ lhs: String, _ rhs: String) -> ComparisonResult) throws {
        let box: Collation = { (lhs: UnsafeRawPointer, rhs: UnsafeRawPointer) in
            let lstr = String(cString: lhs.assumingMemoryBound(to: UInt8.self))
            let rstr = String(cString: rhs.assumingMemoryBound(to: UInt8.self))
            return Int32(block(lstr, rstr).rawValue)
        }
        try check(sqlite3_create_collation_v2(handle, collation, SQLITE_UTF8,
                                              unsafeBitCast(box, to: UnsafeMutableRawPointer.self),
                                              { (callback: UnsafeMutableRawPointer?, _, lhs: UnsafeRawPointer?, _, rhs: UnsafeRawPointer?) in /* xCompare */
                                                if let lhs = lhs, let rhs = rhs {
                                                    return unsafeBitCast(callback, to: Collation.self)(lhs, rhs)
                                                } else {
                                                    fatalError("sqlite3_create_collation_v2 callback called with NULL pointer")
                                                }
        }, nil /* xDestroy */))
        collations[collation] = box
    }
    fileprivate typealias Collation = @convention(block) (UnsafeRawPointer, UnsafeRawPointer) -> Int32
    fileprivate var collations = [String: Collation]()
    
    // MARK: - Error Handling
    
    fileprivate func sync<T>(_ block: () throws -> T) rethrows -> T {
        if DispatchQueue.getSpecific(key: Connection.queueKey) == queueContext {
            return try block()
        } else {
            return try queue.sync(execute: block)
        }
    }
    
    @discardableResult func check(_ resultCode: Int32, statement: Statement? = nil) throws -> Int32 {
        guard let error = Result(errorCode: resultCode, connection: self, statement: statement) else {
            return resultCode
        }
        
        throw error
    }
    
    fileprivate var queue = DispatchQueue(label: "SQLite.Database", attributes: [])
    
    fileprivate static let queueKey = DispatchSpecificKey<Int>()
    
    fileprivate lazy var queueContext: Int = unsafeBitCast(self, to: Int.self)
    
}

extension Connection : CustomStringConvertible {
    
    public var description: String {
        return String(cString: sqlite3_db_filename(handle, nil))
    }
    
}

extension Connection.Location : CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .inMemory:
            return ":memory:"
        case .temporary:
            return ""
        case .uri(let URI):
            return URI
        }
    }
    
}

public enum Result : Error {
    
    fileprivate static let successCodes: Set = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE]
    
    /// Represents a SQLite specific [error code](https://sqlite.org/rescode.html)
    ///
    /// - message: English-language text that describes the error
    ///
    /// - code: SQLite [error code](https://sqlite.org/rescode.html#primary_result_code_list)
    ///
    /// - statement: the statement which produced the error
    case error(message: String, code: Int32, statement: Statement?)
    
    init?(errorCode: Int32, connection: Connection, statement: Statement? = nil) {
        guard !Result.successCodes.contains(errorCode) else { return nil }
        if connection._handle == nil {
            self = .error(message:"create sqlite db error!!!", code:-1, statement:nil)
            return
        }
        let message = String(cString: sqlite3_errmsg(connection.handle))
        self = .error(message: message, code: errorCode, statement: statement)
    }
    
}

extension Result : CustomStringConvertible {
    
    public var description: String {
        switch self {
        case let .error(message, errorCode, statement):
            if let statement = statement {
                return "\(message) (\(statement)) (code: \(errorCode))"
            } else {
                return "\(message) (code: \(errorCode))"
            }
        }
    }
}

#if !SQLITE_SWIFT_SQLCIPHER && !os(Linux)
@available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *)
extension Connection {
    fileprivate func trace_v2(_ callback: ((String) -> Void)?) {
        guard let callback = callback else {
            // If the X callback is NULL or if the M mask is zero, then tracing is disabled.
            sqlite3_trace_v2(handle, 0 /* mask */, nil /* xCallback */, nil /* pCtx */)
            trace = nil
            return
        }
        
        let box: Trace = { (pointer: UnsafeRawPointer) in
            callback(String(cString: pointer.assumingMemoryBound(to: UInt8.self)))
        }
        sqlite3_trace_v2(handle,
                         UInt32(SQLITE_TRACE_STMT) /* mask */,
            {
                // A trace callback is invoked with four arguments: callback(T,C,P,X).
                // The T argument is one of the SQLITE_TRACE constants to indicate why the
                // callback was invoked. The C argument is a copy of the context pointer.
                // The P and X arguments are pointers whose meanings depend on T.
                (T: UInt32, C: UnsafeMutableRawPointer?, P: UnsafeMutableRawPointer?, X: UnsafeMutableRawPointer?) in
                if let P = P,
                    let expandedSQL = sqlite3_expanded_sql(OpaquePointer(P)) {
                    unsafeBitCast(C, to: Trace.self)(expandedSQL)
                    sqlite3_free(expandedSQL)
                }
                return Int32(0) // currently ignored
        },
            unsafeBitCast(box, to: UnsafeMutableRawPointer.self) /* pCtx */
        )
        trace = box
    }
}
#endif

/// A single SQL statement.
public final class Statement {
    
    fileprivate var handle: OpaquePointer? = nil
    
    fileprivate let connection: Connection
    
    init(_ connection: Connection, _ SQL: String) throws {
        self.connection = connection
        try connection.check(sqlite3_prepare_v2(connection.handle, SQL, -1, &handle, nil))
    }
    
    deinit {
        sqlite3_finalize(handle)
    }
    
    public lazy var columnCount: Int = Int(sqlite3_column_count(self.handle))
    
    public lazy var columnNames: [String] = (0..<Int32(self.columnCount)).map {
        String(cString: sqlite3_column_name(self.handle, $0))
    }
    
    /// A cursor pointing to the current row.
    public lazy var row: Cursor = Cursor(self)
    
    /// Binds a list of parameters to a statement.
    ///
    /// - Parameter values: A list of parameters to bind to the statement.
    ///
    /// - Returns: The statement object (useful for chaining).
    public func bind(_ values: Binding?...) -> Statement {
        return bind(values)
    }
    
    /// Binds a list of parameters to a statement.
    ///
    /// - Parameter values: A list of parameters to bind to the statement.
    ///
    /// - Returns: The statement object (useful for chaining).
    public func bind(_ values: [Binding?]) -> Statement {
        if values.isEmpty { return self }
        reset()
        guard values.count == Int(sqlite3_bind_parameter_count(handle)) else {
            fatalError("\(sqlite3_bind_parameter_count(handle)) values expected, \(values.count) passed")
        }
        for idx in 1...values.count { bind(values[idx - 1], atIndex: idx) }
        return self
    }
    
    /// Binds a dictionary of named parameters to a statement.
    ///
    /// - Parameter values: A dictionary of named parameters to bind to the
    ///   statement.
    ///
    /// - Returns: The statement object (useful for chaining).
    public func bind(_ values: [String: Binding?]) -> Statement {
        reset()
        for (name, value) in values {
            let idx = sqlite3_bind_parameter_index(handle, name)
            guard idx > 0 else {
                fatalError("parameter not found: \(name)")
            }
            bind(value, atIndex: Int(idx))
        }
        return self
    }
    
    fileprivate func bind(_ value: Binding?, atIndex idx: Int) {
        if value == nil {
            sqlite3_bind_null(handle, Int32(idx))
        } else if let value = value as? Blob {
            sqlite3_bind_blob(handle, Int32(idx), value.bytes, Int32(value.bytes.count), SQLITE_TRANSIENT)
        } else if let value = value as? Double {
            sqlite3_bind_double(handle, Int32(idx), value)
        } else if let value = value as? Int64 {
            sqlite3_bind_int64(handle, Int32(idx), value)
        } else if let value = value as? String {
            sqlite3_bind_text(handle, Int32(idx), value, -1, SQLITE_TRANSIENT)
        } else if let value = value as? Int {
            self.bind(value.datatypeValue, atIndex: idx)
        } else if let value = value as? Bool {
            self.bind(value.datatypeValue, atIndex: idx)
        } else if let value = value {
            fatalError("tried to bind unexpected value \(value)")
        }
    }
    
    /// - Parameter bindings: A list of parameters to bind to the statement.
    ///
    /// - Throws: `Result.Error` if query execution fails.
    ///
    /// - Returns: The statement object (useful for chaining).
    @discardableResult public func run(_ bindings: Binding?...) throws -> Statement {
        guard bindings.isEmpty else {
            return try run(bindings)
        }
        
        reset(clearBindings: false)
        repeat {} while try step()
        return self
    }
    
    /// - Parameter bindings: A list of parameters to bind to the statement.
    ///
    /// - Throws: `Result.Error` if query execution fails.
    ///
    /// - Returns: The statement object (useful for chaining).
    @discardableResult public func run(_ bindings: [Binding?]) throws -> Statement {
        return try bind(bindings).run()
    }
    
    /// - Parameter bindings: A dictionary of named parameters to bind to the
    ///   statement.
    ///
    /// - Throws: `Result.Error` if query execution fails.
    ///
    /// - Returns: The statement object (useful for chaining).
    @discardableResult public func run(_ bindings: [String: Binding?]) throws -> Statement {
        return try bind(bindings).run()
    }
    
    /// - Parameter bindings: A list of parameters to bind to the statement.
    ///
    /// - Returns: The first value of the first row returned.
    public func scalar(_ bindings: Binding?...) throws -> Binding? {
        guard bindings.isEmpty else {
            return try scalar(bindings)
        }
        
        reset(clearBindings: false)
        _ = try step()
        return row[0]
    }
    
    /// - Parameter bindings: A list of parameters to bind to the statement.
    ///
    /// - Returns: The first value of the first row returned.
    public func scalar(_ bindings: [Binding?]) throws -> Binding? {
        return try bind(bindings).scalar()
    }
    
    
    /// - Parameter bindings: A dictionary of named parameters to bind to the
    ///   statement.
    ///
    /// - Returns: The first value of the first row returned.
    public func scalar(_ bindings: [String: Binding?]) throws -> Binding? {
        return try bind(bindings).scalar()
    }
    
    public func step() throws -> Bool {
        return try connection.sync { try self.connection.check(sqlite3_step(self.handle)) == SQLITE_ROW }
    }
    
    fileprivate func reset(clearBindings shouldClear: Bool = true) {
        sqlite3_reset(handle)
        if (shouldClear) { sqlite3_clear_bindings(handle) }
    }
    
}

extension Statement : Sequence {
    
    public func makeIterator() -> Statement {
        reset(clearBindings: false)
        return self
    }
    
}

public protocol FailableIterator : IteratorProtocol {
    func failableNext() throws -> Self.Element?
}

extension FailableIterator {
    public func next() -> Element? {
        do {
            return try failableNext()
        } catch {
            print("ignore error:\(error)")
        }
        return nil
    }
}

extension Array {
    public init<I: FailableIterator>(_ failableIterator: I) throws where I.Element == Element {
        self.init()
        while let row = try failableIterator.failableNext() {
            append(row)
        }
    }
}

extension Statement : FailableIterator {
    public typealias Element = [Binding?]
    public func failableNext() throws -> [Binding?]? {
        return try step() ? Array(row) : nil
    }
}

extension Statement : CustomStringConvertible {
    
    public var description: String {
        return String(cString: sqlite3_sql(handle))
    }
    
}

public struct Cursor {
    
    fileprivate let handle: OpaquePointer
    
    fileprivate let columnCount: Int
    
    fileprivate init(_ statement: Statement) {
        handle = statement.handle!
        columnCount = statement.columnCount
    }
    
    public subscript(idx: Int) -> Double {
        return sqlite3_column_double(handle, Int32(idx))
    }
    
    public subscript(idx: Int) -> Int64 {
        return sqlite3_column_int64(handle, Int32(idx))
    }
    
    public subscript(idx: Int) -> String {
        return String(cString: UnsafePointer(sqlite3_column_text(handle, Int32(idx))))
    }
    
    public subscript(idx: Int) -> Blob {
        if let pointer = sqlite3_column_blob(handle, Int32(idx)) {
            let length = Int(sqlite3_column_bytes(handle, Int32(idx)))
            return Blob(bytes: pointer, length: length)
        } else {
            // The return value from sqlite3_column_blob() for a zero-length BLOB is a NULL pointer.
            // https://www.sqlite.org/c3ref/column_blob.html
            return Blob(bytes: [])
        }
    }
    
    // MARK: -
    
    public subscript(idx: Int) -> Bool {
        return Bool.fromDatatypeValue(self[idx])
    }
    
    public subscript(idx: Int) -> Int {
        return Int.fromDatatypeValue(self[idx])
    }
    
}

/// Cursors provide direct access to a statement’s current row.
extension Cursor : Sequence {
    
    public subscript(idx: Int) -> Binding? {
        switch sqlite3_column_type(handle, Int32(idx)) {
        case SQLITE_BLOB:
            return self[idx] as Blob
        case SQLITE_FLOAT:
            return self[idx] as Double
        case SQLITE_INTEGER:
            return self[idx] as Int64
        case SQLITE_NULL:
            return nil
        case SQLITE_TEXT:
            return self[idx] as String
        case let type:
            fatalError("unsupported column type: \(type)")
        }
    }
    
    public func makeIterator() -> AnyIterator<Binding?> {
        var idx = 0
        return AnyIterator {
            if idx >= self.columnCount {
                return Optional<Binding?>.none
            } else {
                idx += 1
                return self[idx - 1]
            }
        }
    }
    
}

public protocol Binding {}
public protocol Number : Binding {}
public protocol Value /*: Expressible*/ { // extensions cannot have inheritance clauses
    
    associatedtype ValueType = Self
    
    associatedtype Datatype : Binding
    
    static var declaredDatatype: String { get }
    
    static func fromDatatypeValue(_ datatypeValue: Datatype) -> ValueType
    
    var datatypeValue: Datatype { get }
    
}

extension Double : Number, Value {
    
    public static let declaredDatatype = "REAL"
    
    public static func fromDatatypeValue(_ datatypeValue: Double) -> Double {
        return datatypeValue
    }
    
    public var datatypeValue: Double {
        return self
    }
    
}

extension Int64 : Number, Value {
    
    public static let declaredDatatype = "INTEGER"
    
    public static func fromDatatypeValue(_ datatypeValue: Int64) -> Int64 {
        return datatypeValue
    }
    
    public var datatypeValue: Int64 {
        return self
    }
    
}

extension String : Binding, Value {
    
    public static let declaredDatatype = "TEXT"
    
    public static func fromDatatypeValue(_ datatypeValue: String) -> String {
        return datatypeValue
    }
    
    public var datatypeValue: String {
        return self
    }
    
}

public struct Blob {
    
    public let bytes: [UInt8]
    
    public init(bytes: [UInt8]) {
        self.bytes = bytes
    }
    
    public init(bytes: UnsafeRawPointer, length: Int) {
        let i8bufptr = UnsafeBufferPointer(start: bytes.assumingMemoryBound(to: UInt8.self), count: length)
        self.init(bytes: [UInt8](i8bufptr))
    }
    
    public func toHex() -> String {
        return bytes.map {
            ($0 < 16 ? "0" : "") + String($0, radix: 16, uppercase: false)
            }.joined(separator: "")
    }
    
}

extension Blob : CustomStringConvertible {
    
    public var description: String {
        return "x'\(toHex())'"
    }
    
}

extension Blob : Equatable {
    
}

public func ==(lhs: Blob, rhs: Blob) -> Bool {
    return lhs.bytes == rhs.bytes
}

extension Blob : Binding, Value {
    
    public static let declaredDatatype = "BLOB"
    
    public static func fromDatatypeValue(_ datatypeValue: Blob) -> Blob {
        return datatypeValue
    }
    
    public var datatypeValue: Blob {
        return self
    }
    
}

// MARK: -

extension Bool : Binding, Value {
    
    public static var declaredDatatype = Int64.declaredDatatype
    
    public static func fromDatatypeValue(_ datatypeValue: Int64) -> Bool {
        return datatypeValue != 0
    }
    
    public var datatypeValue: Int64 {
        return self ? 1 : 0
    }
    
}

extension Int : Number, Value {
    
    public static var declaredDatatype = Int64.declaredDatatype
    
    public static func fromDatatypeValue(_ datatypeValue: Int64) -> Int {
        return Int(datatypeValue)
    }
    
    public var datatypeValue: Int64 {
        return Int64(self)
    }
    
}

//
//  DataStore.swift
//  ttt
//
//  Created by lingminjun on 2018/5/4.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

let SSNDataStoreDir = "ssndatastore"

let SSNDataStoreNotification = "SSN.DataStore.Notification"
let SSNDataStoreNotificationOperationKey = "SSN.DataStore.Notification.Operation.Key"

/**
 *  目录类型
 */
enum StoreDirectory {
    case document/*Document目录下*/,caches/*Library/Caches目录下*/,temporary/*tmp目录下*/
}


public class DataStore : Equatable {
    
    public static func == (lhs: DataStore, rhs: DataStore) -> Bool {
        return lhs._scope == rhs._scope
    }
    

    /**
     @brief Documents/ssnstore/[scope]目录下缓存
     */
    public static func documentsStore(withScope scope:String) -> DataStore {
        return documents.get(scope)!
    }
    private static let documents: RigidCache<DataStore> = {
        let cache = RigidCache<DataStore>({ (scope, info) -> DataStore in
            let store = DataStore(scope:scope,directory:.document)
            return store
        }, size: 1)
        return cache
    }()
    
    
    /**
     @brief Library/Caches/ssnstore/[scope]目录下缓存
     */
    public static func cachesStoreWithScope(withScope scope:String) -> DataStore {
        return caches.get(scope)!
    }
    private static let caches: RigidCache<DataStore> = {
        let cache = RigidCache<DataStore>({ (scope, info) -> DataStore in
            let store = DataStore(scope:scope,directory:.caches)
            return store
        }, size: 1)
        return cache
    }()
    
    /**
     @brief tmp/ssnstore/[scope]目录下缓存
     */
    public static func temporaryStore(withScope scope:String) -> DataStore {
        return temporary.get(scope)!
    }
    private static let temporary: RigidCache<DataStore> = {
        let cache = RigidCache<DataStore>({ (scope, info) -> DataStore in
            let store = DataStore(scope:scope,directory:.temporary)
            return store
        }, size: 1)
        return cache
    }()

    public var scope:String { get { return _scope } }
    
    init(scope:String, directory:StoreDirectory = .document) {
        self._scope = scope
        self._directoryType = directory
        
        pthread_mutexattr_init(&attr);
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);  // 定义锁的属性
        pthread_mutex_init(&mutex0, &attr) // 创建锁
        pthread_mutex_init(&mutex1, &attr) // 创建锁
        pthread_mutex_init(&mutex2, &attr) // 创建锁
        pthread_mutex_init(&mutex3, &attr) // 创建锁
        
        let manager = FileManager()
        switch directory {
        case .document:
            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            _path = URL(fileURLWithPath: paths[0].appending("/\(SSNDataStoreDir)/\(scope)"))
        case .caches:
            let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
            _path = URL(fileURLWithPath: paths[0].appending("/\(SSNDataStoreDir)/\(scope)"))
        case .temporary:
            let path = NSTemporaryDirectory()
            _path = URL(fileURLWithPath: path.appending("/\(SSNDataStoreDir)/\(scope)"))
        }
        if !manager.fileExists(atPath: _path.path) {
            try! manager.createDirectory(at: _path, withIntermediateDirectories: true, attributes: nil)
        }
    }
    
    deinit {
        pthread_mutex_destroy(&mutex0)
        pthread_mutex_destroy(&mutex1)
        pthread_mutex_destroy(&mutex2)
        pthread_mutex_destroy(&mutex3)
        pthread_mutexattr_destroy(&attr)
        print("DataStore[\(_scope)] deinit ")
    }
    
    ////// 对象支持
    public func model<T>(forKey key:String, type: T.Type) -> T? where T : Decodable {
        guard let data = data(forKey: key) else {
            return nil
        }
        let decoder = JSONDecoder()
        guard let model = try? decoder.decode(type, from: data) else {
            return nil
        }
        return model
    }
    
    public func accessModel<T>(forKey key:String, type: T.Type) -> T? where T : Decodable  {
        guard let data = accessData(forKey: key) else {
            return nil
        }
        let decoder = JSONDecoder()
        guard let model = try? decoder.decode(type, from: data) else {
            return nil
        }
        return model
    }
    
    public func model<T>(forKey key:String, isExpired: inout Bool, type: T.Type) -> T? where T : Decodable {
        guard let data = data(forKey: key, isExpired: &isExpired) else {
            return nil
        }
        let decoder = JSONDecoder()
        guard let model = try? decoder.decode(type, from: data) else {
            return nil
        }
        return model
    }
    
    public func accessModel<T>(forKey key:String, isExpired: inout Bool, type: T.Type) -> T? where T : Decodable {
        guard let data = accessData(forKey: key, isExpired: &isExpired) else {
            return nil
        }
        let decoder = JSONDecoder()
        guard let model = try? decoder.decode(type, from: data) else {
            return nil
        }
        return model
    }
    
    /// 注意，由于Encodable协议泛型限定，必须传入实现的Encodable协议的实例对象
    public func store<T>(model:T, forKey key:String, expire:Int64 = 0) -> Void where T : Encodable {
        let encoder = JSONEncoder()
        //open func encode<T>(_ value: T) throws -> Data where T : Encodable
        guard let data = try? encoder.encode(model) else {
            return
        }
        store(data: data, forKey: key, expire: expire)
    }
    
    public func removeModel(forKey key:String) {
        removeData(forKey: key)
    }
    
    ////// 对字符串支持
    public func string(forKey key:String) -> String {
        if let data = data(forKey: key), let str = String(data: data, encoding: String.Encoding.utf8) {
            return str
        } else {
            return ""
        }
    }
    
    public func accessString(forKey key:String) -> String {
        if let data = accessData(forKey: key), let str = String(data: data, encoding: String.Encoding.utf8) {
            return str
        } else {
            return ""
        }
    }
    
    public func string(forKey key:String, isExpired: inout Bool) -> String {
        if let data = data(forKey: key, isExpired: &isExpired), let str = String(data: data, encoding: String.Encoding.utf8) {
            return str
        } else {
            return ""
        }
    }
    
    public func accessString(forKey key:String, isExpired: inout Bool) -> String {
        if let data = accessData(forKey: key, isExpired: &isExpired), let str = String(data: data, encoding: String.Encoding.utf8) {
            return str
        } else {
            return ""
        }
    }
    
    public func store(string:String, forKey key:String, expire:Int64 = 0) {
        if let data = string.data(using: String.Encoding.utf8) {
            store(data: data, forKey: key, expire: expire)
        }
    }
    
    public func removeString(forKey key:String) {
        removeData(forKey: key)
    }
    
    /**
     @brief key对应的存储的文件内容
     @param key 需要寻找的key
     @return 返回找到的数据，可能返回nil
     */
    public func data(forKey key:String) -> Data? {
        if key.isEmpty {
            return nil
        }
        var isExpired = false
        let data = innerData(forKey:key, isExpired:&isExpired, updateVisitAt:true)
        
        if (isExpired) {
            return nil
        }
        
        return data
    }
    
    /**
     @brief key对应的存储的文件内容，文件过期返回nil，不更新文件访问实效性
     @param key 需要寻找的key
     @return 返回找到的数据，可能返回nil
     */
    public func accessData(forKey key:String) -> Data? {
        if key.isEmpty {
            return nil
        }
        
        var isExpired = false
        let data = innerData(forKey:key, isExpired:&isExpired, updateVisitAt:false)
        if (isExpired) {
            return nil
        }
        
        return data
    }
    
    /**
     @brief key对应的存储的文件内容，文件过期仍然返回，将在isExpired中标识，更新文件访问实效性
     @param key 需要寻找的key
     @param isExpired 数据是否过期
     @return 返回找到的数据，可能返回nil
     */
    public func data(forKey key:String, isExpired: inout Bool) -> Data? {
        if key.isEmpty {
            isExpired = true
            return nil
        }
        
        return innerData(forKey:key, isExpired:&isExpired, updateVisitAt:true)
    }
    
    /**
     @brief key对应的存储的文件内容，数据过期仍然返回，将在isExpired中标识过期，不更新数据访问实效性
     @param key 需要寻找的key
     @param isExpired 数据是否过期
     @return 返回找到的数据，可能返回nil，找到过期仍然返回
     */
    public func accessData(forKey key:String, isExpired: inout Bool) -> Data? {
        if key.isEmpty {
            isExpired = true
            return nil
        }
        return innerData(forKey:key, isExpired:&isExpired, updateVisitAt:false)
    }
    
    private func innerData(forKey key:String, isExpired: inout Bool, updateVisitAt:Bool) -> Data? {
        
        let now = getNowTime()
        
        var expire:Int64 = 0
        var saveAt:Int64 = 0
        
        //需要从文件中获取
        let lock = getLock(forKey: key)
        pthread_mutex_lock(lock)
        let data = dataFromFile(forKey:key, expire:&expire, saveAt:&saveAt, visitAt:now, isExpired:&isExpired, readonly:!updateVisitAt)
        pthread_mutex_unlock(lock)
        
        return data;
    }
    
    /**
     @brief 将数据存放到对应的key下面
     @param key 对应的key
     @param expire 过期时间(秒)，传入零表示永远不过期
     */
    public func store(data:Data, forKey key:String, expire:Int64 = 0) {
        if key.isEmpty || data.isEmpty {
            return
        }
        
        let now = getNowTime()
        
        let lock = getLock(forKey: key)
        pthread_mutex_lock(lock)
        saveToFile(withData:data, forKey:key, expire:expire, visitAt:now)
        pthread_mutex_unlock(lock)
        
        // 发起通知
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name(self._scope + "." + SSNDataStoreNotification), object: key)
        }
    }
    
    /**
     @brief 删除对应的数据
     @param key 对应的key
     */
    public func removeData(forKey key:String) {
        if key.isEmpty {
            return
        }
        
        let lock = getLock(forKey: key)
        pthread_mutex_lock(lock)
        removeFile(forKey:key)
        pthread_mutex_unlock(lock)
        
        // 发起通知
        DispatchQueue.main.async {
            let info = ["operation":"delete"]
            NotificationCenter.default.post(name: NSNotification.Name(self._scope + "." + SSNDataStoreNotification), object: key, userInfo:info)
        }
    }
    
    
    
    /**
     @brief 返回数据存放位置
     @param key 需要寻找的key
     @return 返回路径（绝对路径），可能返回nil
     */
    private func dataPath(forKey key:String) -> URL {
        let md5 = key.ssn_md5()
        let header = md5[md5.startIndex..<md5.index(md5.startIndex, offsetBy: 2)]//
        return _path.appendingPathComponent(String(header)).appendingPathComponent("\(md5).dt")
    }
    
    private func dataTail(forDataPath path:URL) -> URL {
        return URL(fileURLWithPath: "\(path.path).tail")
    }
    
    
    /**
     @brief 整理磁盘，主要清除过期文件， 非线程安全
     */
    public func tidyDisk() {
        
        //扫描目录
        let manager = FileManager()
        if let subpaths = try? manager.subpathsOfDirectory(atPath: _path.path) {
            let now = getNowTime()
            subpaths.forEach { (subPath) in
                if subPath.hasSuffix(".tail") {//找到对应的时间文件
                    
                    let tailpath = _path.appendingPathComponent(subPath)
                    var expired:Int64 = 0
                    var saveAt:Int64 = 0
                    let isExpired = checkExpired(&expired, saveAt:&saveAt, visitAt:now, atTailPath:tailpath, updateVisitAt:false)
                    if (isExpired) {
                        let path = tailpath.path
                        let filepath = path[path.startIndex..<path.index(path.endIndex, offsetBy: -5)] //去掉末尾的 .tail
                        try? manager.removeItem(atPath: String(filepath))
                    }
                    
                }
            }
        }
    }
    
    
    /**
     @brief 清理磁盘【不可逆】, 非线程安全
     */
    public func clearDisk() {
        
        //目录删除
        let manager = FileManager()
        if manager.fileExists(atPath: _path.path) {
            try? manager.removeItem(at: _path)
        }
        try? manager.createDirectory(at: _path, withIntermediateDirectories: true, attributes: nil)
    }
    
    
    // #pragma mark 文件存储实现
    private func getNowTime() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
    
    private func updateTail(expire:Int64, visitAt:Int64, atFilePath filepath:URL) {
        let tailpath = dataTail(forDataPath:filepath)
        var mark = ""
        if expire > 0 {
            mark = "\(visitAt),\(expire)"
        }
        
        let manager = FileManager()
        if mark.isEmpty {
            try? manager.removeItem(at: tailpath)
        } else {
            try? mark.write(to: tailpath, atomically: true, encoding: String.Encoding.utf8)
        }
    }
    
    private func checkExpired(_ expire:inout Int64, saveAt: inout Int64, visitAt:Int64, atTailPath tailpath:URL, updateVisitAt:Bool) -> Bool {
        
        let manager = FileManager()
        guard let data = manager.contents(atPath: tailpath.path) else {
            expire = 0
            return false
        }
        
        let content = String(data: data, encoding: String.Encoding.utf8)
        guard let strs = content?.split(separator: ","), strs.count == 2 else {
            expire = 0
            return false
        }
        
        guard let o_visitAt =  Int64(strs[0]),let o_expire =  Int64(strs[1]) else {
            expire = 0
            return false
        }
        
        saveAt = o_visitAt
        expire = o_expire
        
        let isExpired = (o_expire + o_visitAt <= visitAt)
        
        if (isExpired) {//过期删除
            try? manager.removeItem(at: tailpath)
        } else if updateVisitAt {
            try? "\(visitAt),\(expire)".write(to: tailpath, atomically:true, encoding: String.Encoding.utf8)
        }
        
        return isExpired;
    }
    
    
    private func saveToFile(withData data:Data, forKey key:String, expire:Int64, visitAt:Int64) {
        let manager = FileManager()
        let filepath = dataPath(forKey:key)
        let dirpath = filepath.deletingLastPathComponent()
        
        if !manager.fileExists(atPath: dirpath.path) {
            try? manager.createDirectory(at: dirpath, withIntermediateDirectories: true, attributes: nil)
        }
        
        updateTail(expire: expire, visitAt: visitAt, atFilePath: filepath)//更新时间
        try? data.write(to: filepath)
    }
    
    private func dataFromFile(forKey key:String, expire:inout Int64, saveAt:inout Int64, visitAt:Int64, isExpired pIsExpired:inout Bool, readonly:Bool) -> Data? {
        let manager = FileManager()
        let filepath = dataPath(forKey:key)
        
        let data = manager.contents(atPath: filepath.path)
        
        let tailpath = dataTail(forDataPath:filepath)
        
        let isExpired = checkExpired(&expire ,saveAt:&saveAt, visitAt:visitAt, atTailPath:tailpath, updateVisitAt:!readonly)
        pIsExpired = isExpired
        
        if (isExpired) {//文件确实过期，删除掉
            try? manager.removeItem(at: filepath)
        }
        
        return data
    }
    
    private func removeFile(forKey key:String) {
        let manager = FileManager()
        let filepath = dataPath(forKey:key)
        if manager.fileExists(atPath: filepath.path) {
            try? manager.removeItem(at: filepath)
            updateTail(expire: 0, visitAt: 0, atFilePath: filepath)//传入零删除日志文件
        }
    }
    
    private func getLock(forKey key:String) -> UnsafeMutablePointer<pthread_mutex_t> {
        let idx = key.hashValue % 4
        if idx == 0 {
            return UnsafeMutablePointer<pthread_mutex_t>(&mutex0)
        } else if idx == 1 {
            return UnsafeMutablePointer<pthread_mutex_t>(&mutex1)
        } else if idx == 2 {
            return UnsafeMutablePointer<pthread_mutex_t>(&mutex2)
        } else if idx == 3 {
            return UnsafeMutablePointer<pthread_mutex_t>(&mutex3)
        }
        return UnsafeMutablePointer<pthread_mutex_t>(&mutex0)
    }
    
    //采用分锁解冲突模式
    private var attr:pthread_mutexattr_t = pthread_mutexattr_t()
    private var mutex0:pthread_mutex_t = pthread_mutex_t()
    private var mutex1:pthread_mutex_t = pthread_mutex_t()
    private var mutex2:pthread_mutex_t = pthread_mutex_t()
    private var mutex3:pthread_mutex_t = pthread_mutex_t()
    
    private var _scope:String = ""
    private var _path:URL
    private var _directoryType:StoreDirectory = .document
}

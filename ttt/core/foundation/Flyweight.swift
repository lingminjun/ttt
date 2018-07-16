//
//  Flyweight.swift
//  ttt
//
//  Created by lingminjun on 2018/5/1.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

/**
 * Data model protocol
 */
public protocol FlyModel:Codable {
    //业务主键 对应 primary column
    var data_unique_id:String {get}
    //操作数
    var data_sync_flag:Int64 {get set}
}

/**
 * Data update notice
 */
public protocol FlyNotice:AnyObject {
    func on_data_update(dataId:String, model: FlyModel?, isDeleted: Bool)
}

/**
 * Persistence
 */
public protocol FlyPersistence {
    func persistent_queryData(dataId: String) -> FlyModel?
    func persistent_saveData(dataId: String, model: FlyModel)
    func persistent_removeData(dataId: String)
    
    func persistent_set_notice(notice: FlyNotice)
}

/**
 * Remote accessor
 */
public protocol FlyRemoteAccessor {
    func remote_get(dataId:String) -> FlyModel?
}


/// 以数据为中心的同步机制，类似于DataLive，将同步多个模块以及页面之间的数据状态
public class Flyweight<Value: FlyModel> : FlyNotice {

    init(capacity: Int, psstn: FlyPersistence? = nil, remote: FlyRemoteAccessor? = nil, flag:Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
        self._cache = LRUCache<String, Value>(maxCapacity: capacity)
        self.remote = remote
        self.flag = flag
        if psstn != nil {
            self.psstn = psstn
            monitorPersistent()
        }
    }
    
    public var count: Int {
        return _cache.count
    }
    
    /**
     * Data and notice binding
     * @param notice Caution! weak reference
     */
    public func bind(_ model: Value, notice: FlyNotice) {
        bind(model.data_unique_id, notice: notice);
    }
    
    /**
     * Data and notice binding
     * @param dataId
     * @param type
     * @param notice
     * @return model instance
     */
    public func bind(_ dataId:String, notice: FlyNotice) {
        
        addObserver(dataId,notice:notice)
        
        //收绑定必定调用notice方法
        var listeners:[FlyNotice] = []
        listeners.append(notice)
        if (isMainThread()) {
            DispatchQueue.global().async {
                self.loadModel(dataId,notices:listeners);
            }
        } else {
            loadModel(dataId,notices:listeners);
        }
        
    }
    
    /**
     * 解除绑定
     * @param notice
     */
    public func unbind(_ notice:FlyNotice) {
        let code = getNoticeCode(notice: notice)
        clearObserver(code:code)
    }
    
    
    public func save( _ model: Value, latest: Bool = true) {
        
        let dataId = model.data_unique_id
        
        if dataId.isEmpty {
            return;
        }
        
        var m = dataClone(model:model)
        if (latest) {
            m.data_sync_flag = flag
        }
        
        let listeners = getObserver(dataId)
        updateModel(m,notices:listeners,persistent:latest)
    }
    
    public func remove(_ dataId:String) {
        if dataId.isEmpty {
            return
        }
        let listeners = getObserver(dataId)
        removeModel(dataId,notices:listeners)
    }
    
    /**
     * 清除所有内存对象
     */
    public func restore() {
        _cache.removeAll()
    }
    
    // MARK: - private
    private func dataClone(model:Value) -> Value {
        guard let data = try? JSONEncoder().encode(model) else {
            return model
        }
        guard let m = try? JSONDecoder().decode(Value.self, from: data) else {
            return model
        }
        return m
    }
    
    /**
     * 清除所有已经释放对象
     */
    private func clean() {//synchronized
        self.synchronized {
            for (_,list) in obs.enumerated() {
                for ob in list.value {
                    if ob.obj == nil {
                        clearObserver(code: ob.code)
                    }
                }
            }
        }
    }
    
    private func loadModel(_ dataId:String, notices:[FlyNotice]) {
        var obj:Value? = _cache[dataId]
        let nocache = obj == nil
        
        if (obj == nil && psstn != nil) {
            obj = psstn?.persistent_queryData(dataId: dataId) as? Value
            if let model = obj {
                obj = dataClone(model: model)
            }
        }
        
        //本地获取数据后，仍然可能需要从远程获取数据
        var needSync = false;
        if obj == nil && remote != nil {
            obj = remote?.remote_get(dataId:dataId) as? Value
            if (obj != nil) {
                obj?.data_sync_flag = flag
            }
        } else if var model = obj, model.data_sync_flag != flag && remote != nil {//需要进一步去服务端验证
            needSync = true;
        }
        
//        if (obj == nil && clazz != null) {//创建实例（并cache起来）
//            obj = TR.instanceForName(clazz.getName(),clazz);
//        }
        
        if nocache && obj != nil {
            _cache[dataId] = obj
        }
        
        if let model = obj {
            notice(dataId,model:model,notices:notices)
        }
        
        if (needSync && remote != nil) {
            //去服务端同步，并更新
            obj = remote?.remote_get(dataId:dataId) as? Value
            if (obj != nil) {
                obj?.data_sync_flag = flag
                _cache[dataId] = obj
                let lss = getObserver(dataId)
                notice(dataId,model:obj!,notices:lss);//第二次更新
            }
        }
        
        // 检查并清除一次
        clean();
    }
    
    private func updateModel(_ model:Value, notices:[FlyNotice], persistent:Bool) {
        let dataId = model.data_unique_id
        if  dataId.isEmpty {
            return
        }
        
        _cache[dataId] = model
        
        if persistent && psstn != nil {
            psstn?.persistent_saveData(dataId: dataId,model: model)
        }
        
        notice(dataId,model:model,notices:notices)
    }
    
    private func removeModel(_ dataId:String, notices:[FlyNotice]) {
        let obj:Value? = _cache.removeValue(forKey: dataId)
        
        if psstn != nil {
            psstn?.persistent_removeData(dataId: dataId)
        }
        
        notice(dataId,model:obj,isDeleted:true,notices:notices);
    }
    
    private func notice(_ dataId:String, model:Value?, isDeleted: Bool = false, notices: [FlyNotice]) {
        if notices.isEmpty {
            return
        }
        if (isMainThread()) {
            for notice in notices {
                notice.on_data_update(dataId:dataId, model: model, isDeleted: isDeleted)
            }
        } else {
            DispatchQueue.main.async {
                for notice in notices {
                    notice.on_data_update(dataId:dataId, model: model, isDeleted: isDeleted)
                }
            }
        }
    }
    
    public func on_data_update(dataId:String, model: FlyModel?, isDeleted: Bool) {
        if let m = model as? Value {
            lookOverListeners(dataId:dataId ,model: m, isDeleted: isDeleted)
        }
    }
    
    private func monitorPersistent() {
        psstn?.persistent_set_notice(notice: self)
    }
    
    private func lookOverListeners(dataId:String, model: Value?, isDeleted:Bool) {
        let listeners = getObserver(dataId)
        if (isDeleted) {
            removeModel(dataId,notices:listeners);
        } else if let model = model {
            updateModel(model, notices:listeners, persistent:false)
        } else if let model = psstn?.persistent_queryData(dataId: dataId) as? Value {
            updateModel(model, notices:listeners, persistent:false)
        } else {
            print("注意，persistent update必须将实例传入，否则可能出现读取误差")
        }
    }
    
    private func isMainThread() -> Bool {
        return Thread.isMainThread
    }
    
    private func clearObserver(code:String) {//synchronized
        self.synchronized {
            guard let dataId = map[code] else {
                return
            }
            
            map.removeValue(forKey: code)
            if var observers = obs[dataId] {
                for idx in 0..<observers.count {
                    let observer = observers[idx]
                    if (observer.code == code) {
                        observers.remove(at: idx)
//                        print(">>> remove \(dataId) \(code)")
                        break
                    }
                }
                
                //全部移除
                if (observers.count == 0) {
                    obs.removeValue(forKey:dataId)
                } else {//重置数据源
                    obs[dataId] = observers
                }
            }
        }
    }
    
    private func getNoticeCode(notice: FlyNotice) -> String {
        /// 方案一： 测试中 发现作用在<引用类型>的对象上能确保正确性
        let point = Unmanaged<AnyObject>.passUnretained(notice as AnyObject).toOpaque()
        let hashValue = point.hashValue // 这个就是唯一的，可以作比较
        
        /// 方案二：测试中 发现作用在<值类型>的对象上能确保正确性
//        let hashValue2 = withUnsafePointer(to: &notice) { (point) -> Int in
//            /// 闭包的实现有多种，可根据自己需求修改
//            return point.hashValue
//        }
        
        return "\(hashValue)"
    }
    
    private func addObserver(_ dataId: String, notice: FlyNotice) {//synchronized
        let code = getNoticeCode(notice: notice)
        
//        print("准备添加 \(dataId) \(code)" )
        self.synchronized {
            var key = map[code]
            if let k = key, k != dataId {//已经添加过了,但是不是注册的同一个dataId
//                print("反复添加 code:\(code)" )
                clearObserver(code: code) //
                key = nil
            }
            
            if key == nil {
                map[code] = dataId
                let observer = WeakObserver(notice as AnyObject, dataId:dataId, code:code)
                var observers = obs[dataId]
                if (observers == nil) {
                    observers = []
                }
                
                if var tobs = observers {
                    tobs.append(observer)
                    obs[dataId] = tobs
//                    print("添加 \(dataId) \(code)" )
                }
            } else {//找到原来对象，并重置notice
                if let observers = obs[dataId] {
                    for ob in observers {
                        if ob.code == code {
                            ob.dataId = dataId
                            ob.obj = notice as AnyObject
//                            print("重置 \(dataId) \(code)" )
                            break
                        }
                    }
                }
            }
        }
    }
    
    private func getObserver(_ dataId:String) -> [FlyNotice] {//synchronized
        var listeners:[FlyNotice] = []
        
        self.synchronized {
            guard let observers = obs[dataId] else {
                return
            }
            
            for observer in observers {
                if let obj = observer.obj as? FlyNotice {
                    listeners.append(obj)
                } else {
                    clearObserver(code: observer.code)
                }
            }
        }
        
        return listeners
    }
    
    private class WeakObserver {
        weak var obj: AnyObject? = nil
        var dataId:String = ""
        var code:String = ""
        init(_ obj: AnyObject, dataId:String, code:String) {
            self.obj = obj
            self.dataId = dataId
            self.code = code
        }
    }
    
    private func synchronized(_ body: () throws -> Void) rethrows {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return try body()
    }
    
    
    
    private var _cache:LRUCache<String,Value>!
    
    private var psstn: FlyPersistence?
    private var remote: FlyRemoteAccessor?
    
    private var flag: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    
    //容器
    private var obs: Dictionary<String, [WeakObserver]> = [:]//所有注册者
    private var map: Dictionary<String, String> = [:]//
}



//
//  Flyweight.swift
//  ttt
//
//  Created by lingminjun on 2018/5/1.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

public class Flyweight<Value: FlyModel> : Notice {
    
    private typealias Node = CacheNode<String, Value>
    
    private var capacity: Int
    private var storage: Dictionary<String, Value>
    private var head: Node?
    private var tail: Node?
    
    private var psstn: Persistence?
    private var remote: RemoteAccessor?
    
    private var flag: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    
    //容器
    private var obs: Dictionary<String, [WeakObserver]> = [:]//所有注册者
    private var map: Dictionary<String, String> = [:]//
    
    //监听对象释放
//    private ReferenceQueue<Listener> _gc = new ReferenceQueue<Listener>();
//    private Thread _mainThread = Looper.getMainLooper().getThread();
    

    init(capacity: Int, psstn: Persistence? = nil, remote: RemoteAccessor? = nil, flag:Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
        self.capacity = capacity
        self.storage = Dictionary<String, Value>(minimumCapacity: capacity)
        self.psstn = psstn
        self.remote = remote
        self.flag = flag
        if psstn != nil {
            monitorPersistent()
        }
    }
    
    private func getCache(key: String) -> Value? {
        if let node = findNode(key) {
            // Move the node to the front of the list
            moveNodeToFront(node)
        }
        
        return storage[key]
    }
    
    private func setCache(key: String, value newValue: Value?) {
        storage[key] = newValue
        
        if let value = newValue {
            // Value was provided. Find the corresponding node, update its value, and move
            // it to the front of the list. If it's not found, create it at the front.
            if let node = findNode(key) {
                node.value = value
                moveNodeToFront(node)
            } else {
                let newNode = Node(key: key, value: value)
                addNodeToFront(newNode)
                
                // Truncate from the tail
                if count > capacity {
                    for _ in capacity..<count {
                        storage[tail!.key] = nil
                        tail = tail?.previous
                    }
                }
            }
        } else {
            // Value was removed. Find the corresponding node and remove it as well.
            if let node = findNode(key) {
                removeNode(node)
            }
        }
    }
    
    public var count: Int {
        return storage.count
    }
    
    /**
     * Data and notice binding
     * @param notice Caution! weak reference
     */
    public func bind(_ model: Value, notice: Notice) {
        bind(model.data_unique_id, notice: notice);
    }
    
    /**
     * Data and notice binding
     * @param dataId
     * @param type
     * @param notice
     * @return model instance
     */
    public func bind(_ dataId:String, notice: Notice) {
        
        addObserver(dataId,notice:notice)
        
        //收绑定必定调用notice方法
        var listeners:[Notice] = []
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
    public func unbind(_ notice:Notice) {
        let code = String(format: "%p", notice as! CVarArg)
        clearObserver(code:code)
    }
    
    
    public func save( _ model: inout Value, latest: Bool = true) {
        
        let dataId = model.data_unique_id
        
        if dataId.isEmpty {
            return;
        }
        
        if (latest) {
            model.data_sync_flag = flag
        }
        
        let listeners = getObserver(dataId)
        updateModel(model,notices:listeners,persistent:latest)
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
        storage.removeAll()
        head = nil
        tail = nil
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
    
    private func loadModel(_ dataId:String, notices:[Notice]) {
        var obj:Value? = self.getCache(key: dataId)
        let nocache = obj == nil
        
        if (obj == nil && psstn != nil) {
            obj = psstn?.persistent_queryData(dataId: dataId) as? Value
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
            self.setCache(key: dataId, value: obj)
        }
        
        if let model = obj {
            notice(model,notices:notices)
        }
        
        if (needSync && remote != nil) {
            //去服务端同步，并更新
            obj = remote?.remote_get(dataId:dataId) as? Value
            if (obj != nil) {
                obj?.data_sync_flag = flag
                self.setCache(key: dataId, value: obj)
                
                let lss = getObserver(dataId)
                notice(obj!,notices:lss);//第二次更新
            }
        }
        
        // 检查并清除一次
        clean();
    }
    
    func updateModel(_ model:Value, notices:[Notice], persistent:Bool) {
        let dataId = model.data_unique_id
        if  dataId.isEmpty {
            return
        }
        
        setCache(key: dataId, value: model)
        
        
        if persistent && psstn != nil {
            psstn?.persistent_saveData(dataId: dataId,model: model)
        }
        
        notice(model,notices:notices)
    }
    
    func removeModel(_ dataId:String, notices:[Notice]) {
        guard let obj = getCache(key: dataId) else {
            return
        }
        setCache(key: dataId, value: nil)

        
        if psstn != nil {
            psstn?.persistent_removeData(dataId: dataId)
        }
        
        notice(obj,isDeleted:true,notices:notices);
    }
    
    func notice(_ model:Value, isDeleted: Bool = false, notices: [Notice]) {
        if notices.isEmpty {
            return
        }
        if (isMainThread()) {
            for notice in notices {
                notice.on_data_update(model: model, isDeleted: isDeleted)
            }
        } else {
            DispatchQueue.main.async {
                for notice in notices {
                    notice.on_data_update(model: model, isDeleted: isDeleted)
                }
            }
        }
    }
    
    public func on_data_update(model: FlyModel, isDeleted: Bool) {
        if let m = model as? Value {
            lookOverListeners(model: m, isDeleted: isDeleted)
        }
    }
    
    func monitorPersistent() {
        psstn?.persistent_set_notice(notice: self)
    }
    
    func lookOverListeners(model:Value, isDeleted:Bool) {
        let dataId = model.data_unique_id
        let listeners = getObserver(dataId)
        if (isDeleted) {
            removeModel(dataId,notices:listeners);
        } else {
            updateModel(model, notices:listeners,persistent:false)
        }
    }
    
    func isMainThread() -> Bool {
        return Thread.isMainThread
    }
    
    func clearObserver(code:String) {//synchronized
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
                        break
                    }
                }
                
                //全部移除
                if (observers.count == 0) {
                    obs.removeValue(forKey:dataId)
                }
            }
        }
    }
    
    func addObserver(_ dataId: String, notice: Notice) {//synchronized
        let code = String(format: "%p", notice as! CVarArg)
        
        //已经添加过了
        self.synchronized {
            let key = map[code]
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
                }
            }
        }
    }
    
    func getObserver(_ dataId:String) -> [Notice] {//synchronized
        var listeners:[Notice] = []
        
        self.synchronized {
            guard let observers = obs[dataId] else {
                return
            }
            
            for observer in observers {
                if let obj = observer.obj as? Notice {
                    listeners.append(obj)
                } else {
                    clearObserver(code: observer.code)
                }
            }
        }
        
        return listeners
    }
    
    
    
    
    // MARK: - private
    private func synchronized(_ body: () throws -> Void) rethrows {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        return try body()
    }
    
    private func addNodeToFront(_ node: Node) {
        if let headNode = head {
            head = node
            node.next = headNode
            headNode.previous = node
        } else {
            head = node
            tail = node
        }
    }
    
    private func moveNodeToFront(_ node: Node) {
        // Link the previous node to the next
        removeNode(node)
        
        // Then prepend this node at the front of the list
        node.next = head
        head = node
    }
    
    private func findNode(_ key: String) -> Node? {
        var node = head
        var found = false
        
        while node != nil {
            if node?.key == key {
                found = true
                break
            } else {
                node = node?.next
            }
        }
        
        if !found {
            node = nil
        }
        
        return node
    }
    
    private func removeNode(_ node: Node) {
        // Remove the given node by linking the previous node to the next
        let previous = node.previous
        let next = node.next
        
        previous?.next = next
        next?.previous = previous
        
        // Update the tail, if necessary
        if tail?.key == node.key {
            tail = previous
        }
    }
}

public protocol FlyModel {
    var data_unique_id:String {get}
    var data_sync_flag:Int64 {get set}
}

/**
 * Data update notice
 */
public protocol Notice {
    func on_data_update(model: FlyModel, isDeleted: Bool)
}

/**
 * Persistence
 */
public protocol Persistence {
    func persistent_queryData(dataId: String) -> FlyModel?
    func persistent_saveData(dataId: String, model: FlyModel)
    func persistent_removeData(dataId: String)
    
    func persistent_set_notice(notice: Notice)
}

/**
 * Remote accessor
 */
public protocol RemoteAccessor {
    func remote_get(dataId:String) -> FlyModel
}

private class CacheNode<String: Hashable, Value> {
    let key: String
    var value: Value
    var previous: CacheNode?
    var next: CacheNode?
    
    init(key: String, value: Value) {
        self.key = key
        self.value = value
    }
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

//
//  FlyweightStore.swift
//  ttt
//
//  Created by lingminjun on 2018/7/16.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit
import HandyJSON

public typealias StoreModel = HandyJSON & FlyModel

/// Flyweight Store Persistence
public class FlyweightStore<T: StoreModel>: FlyPersistence {
    
    
    private var _domain = ""
    private var _scope = ""
    private var _store:DataStore?
    
    init(scope: String, domain: String = "") {
        self._scope = scope
        self._domain = domain
    }
    
    
    private var store:DataStore? {
        get {
            
            if _store != nil {
                return _store
            }
            if !_domain.isEmpty && !_scope.isEmpty {
                _store = DataStore.documentsStore(withScope: _domain+"/"+_scope)
            } else if !_scope.isEmpty {
                _store = DataStore.documentsStore(withScope: "flyweight/"+_scope)
            }
            
            return _store
        }
    }
    
    /// 切换用户
    public func switchStoreDomain(_ domain: String) {
        self._domain = domain
        self._store = nil
    }
    
    
    public func persistent_queryData(dataId: String) -> FlyModel? {
        return store?.model(forKey: dataId, type: T.self)
    }
    
    public func persistent_saveData(dataId: String, model: FlyModel) {
        //由于coding协议采用泛型定义，无法从协议转向泛型，故采用如下方式转化
        if let inner = model as? StoreModel, let json = inner.toJSONString(),let data = json.data(using: String.Encoding.utf8) {
            self.store?.store(data: data, forKey: dataId)
        }
    }
    
    private func headle_persistent_saveData<M>(dataId: String, model: M) -> Void where M : FlyModel  {
        self.store?.store(model: model, forKey: dataId)
    }
    
    public func persistent_removeData(dataId: String) {
        self.store?.removeModel(forKey: dataId)
    }
    
    public func persistent_set_notice(notice: FlyNotice) {
        //
    }
}

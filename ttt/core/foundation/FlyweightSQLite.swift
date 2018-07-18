//
//  FlyweightSQLite.swift
//  ttt
//
//  Created by lingminjun on 2018/7/15.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import HandyJSON


public typealias SQLFlyModel = DBModel & FlyModel

/// Flyweight SQLite Persistence
public class FlyweightSQLite<T:SQLFlyModel>: FlyPersistence {
    
    private var _table:DBTable!
    private var _callback:FlyNotice? = nil
    private var _map:[Int64:String] = [:] //如何找到rowid与data_id的对应关系
    private var _column = ""
    
    
    public init(db:DB, table:String, template:String = "", primary column:String = "") {
        self._table = DBTable.table(db: db, name: table, template: template)
        self._column = column
        if column.isEmpty && self._table.primarieColumnName.count == 1 {
            self._column = self._table.primarieColumnName[0]
        }
        if let tb = self._table {
            //监听
            NotificationCenter.default.addObserver(self, selector: #selector(FlyweightSQLite.tableUpdateNotice(notfication:)), name: DBTABLE_DATA_CHANGED_NOTICE, object: tb)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func tableUpdateNotice(notfication: NSNotification) {
        //消息转发，仅仅关注此表修改
        if let callback = _callback {
            guard let info = notfication.userInfo, let rowid = info[SQLITE_ROW_ID_KEY] as? Int64, let opt = info[SQLITE_OPERATION_KEY] as? DB.Operation else { return }
                
            if opt == .delete,let dataId = _map[rowid] {
                callback.on_data_update(dataId: dataId, model: nil, isDeleted: true)
                _map.removeValue(forKey: rowid)
            } else if let obj = _table.object(T.self, conditions: ["rowid":rowid]) {
                _map[rowid] = obj.data_unique_id
                callback.on_data_update(dataId: obj.data_unique_id, model: obj, isDeleted: false)
            }
        }
    }
    
    public func persistent_queryData(dataId: String) -> FlyModel? {
        if let obj = _table.object(T.self, conditions: [self._column:dataId]) {
            _map[obj.ssn_rowid] = obj.data_unique_id
           return obj
        }
        return nil
    }
    
    public func persistent_saveData(dataId: String, model: FlyModel) {
        if let data = model as? SQLFlyModel {
            _table.upinsert(object: data)
            //记录下rowid与data关系
            if let obj = _table.object(T.self, conditions: [self._column:dataId]) {
                _map[obj.ssn_rowid] = obj.data_unique_id
            }
        }
    }
    
    public func persistent_removeData(dataId: String) {
        _table.delete(primary: self._column, value: dataId)
    }
    
    public func persistent_set_notice(notice: FlyNotice) {
        _callback = notice
    }
    
    
    //
}

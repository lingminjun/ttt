//
//  MMUITableController.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/19.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit

public class MMUITableController<T: MMCellModel>: MMUIController,UITableViewDelegate,MMFetchsControllerDelegate {
    
    var table: UITableView { get {return _table } }
    var fetchs: MMFetchsController<T> { get {return _fetchs } }
    
    
    public override func onLoadView() -> Bool {
        self.view = UIView(frame:UIScreen.main.bounds)
        _table = UITableView(frame:self.view.bounds,style:.plain)
        _table.delegate = self
        _table.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        self.view.addSubview(_table)
        return true
    }
    
    ///  Derived class implements.
    public func loadFetchs() -> [MMFetch<T>] {
        /*
        /// realm fetch create
        let realm = try! Realm()
        let vs = realm.objects(Dog.self)
        let ff = vs.sorted(byKeyPath: "breed", ascending: true)
        let f = MMFetchRealm(result:ff,realm:realm)
         
         ///
         //let f = MMFetchList(list:initDataList())
         
         return [f]
        */
        return []
    }
    
    public override func onViewDidLoad() {
        super.onViewDidLoad()
        
        _fetchs = MMFetchsController(fetchs: loadFetchs())
        _fetchs.delegate = self
        _table.dataSource = _fetchs
        
    }
    
    deinit {
        _table?.dataSource = nil
        _table?.delegate = nil
    }
    
    // MARK:- UITableViewDelegate代理
//    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        print("\(scrollView)")
//    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("点击了\(indexPath.row) section:\(indexPath.section)")
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    /// MARK MMFetchsControllerDelegate
    public func ssn_controller(_ controller: AnyObject, deletes: [IndexPath]?, inserts: [IndexPath]?, updates: [IndexPath]?) {
        //_fetchs.perform(_table, deletes: deletes, inserts: inserts, updates: updates, at: section, optimizing: optimizing)
    }
    
    public func ssn_controllerWillChangeContent(_ controller: AnyObject) {
        //_table.beginUpdates()
    }
    
    public func ssn_controllerDidChangeContent(_ controller: AnyObject) {
        //_table.endUpdates()
    }
    
    private var _table : UITableView!
    private var _fetchs : MMFetchsController<T>!
}

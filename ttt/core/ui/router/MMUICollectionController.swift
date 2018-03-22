//
//  MMUICollectionController.swift
//  ttt
//
//  Created by lingminjun on 2018/3/1.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

import UIKit

public class MMUICollectionController<T: MMCellModel>: MMUIController,UICollectionViewDelegate,MMCollectionViewDelegate,MMFetchsControllerDelegate {
    
    var layout:MMCollectionViewLayout { get {return _layout } }
    var table: UICollectionView { get {return _table } }
    var fetchs: MMFetchsController<T> { get {return _fetchs } }
    
    
    public override func onLoadView() -> Bool {
        self.view = UIView(frame:UIScreen.main.bounds)
        _layout = MMCollectionViewLayout(loadLayoutConfig())
        _table = UICollectionView(frame: self.view.bounds, collectionViewLayout: layout)
        _table.delegate = self
        _table.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        self.view.addSubview(_table)
        return true
    }
    
    ///  Derived class implements.
    public func loadLayoutConfig() -> MMLayoutConfig { return MMLayoutConfig() }
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
        _table.performBatchUpdates({
            //nothing
        }, completion: nil)
        
    }
    
    deinit {
        _table.dataSource = nil
        _table.delegate = nil
    }
    
    // MARK:- UICollectionViewDelegate MMCollectionViewDelegate 代理
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("点击了\(indexPath.row) section:\(indexPath.section)")
        collectionView.deselectItem(at: indexPath, animated: false)
    }
    //可以漂浮停靠在界面顶部
    func collectionView(_ collectionView: UICollectionView, canFloatingCellAt indexPath: IndexPath) -> Bool {
        guard let m = _fetchs.object(at: indexPath) else {
            return false
        }
        return m.ssn_canFloating()
    }
    
    //cell的行高,若scrollDirection == .horizontal则返回的是宽度
    public func collectionView(_ collectionView: UICollectionView, heightForCellAt indexPath: IndexPath) -> CGFloat {
        if _layout.config.rowHeight > 0 {
            return layout.config.rowHeight
        }
        guard let m = _fetchs.object(at: indexPath) else {
            return 44
        }
        return m.ssn_cellHeight()
    }
    
    //cell是否SpanSize，返回值小于等于零时默认为1
    public func collectionView(_ collectionView: UICollectionView, spanSizeForCellAt indexPath: IndexPath) -> Int {
        guard let m = _fetchs.object(at: indexPath) else {
            return 1
        }
        if m.ssn_canFloating() || m.ssn_isExclusiveLine() {
            return _layout.config.columnCount
        }
        return m.ssn_cellGridSpanSize()
    }
    
    /// MARK MMFetchsControllerDelegate
    private class Node {
        var object: MMCellModel?
        var type:MMFetchChangeType
        var indexPath:IndexPath
        var newIndexPath:IndexPath?
        init(type: MMFetchChangeType, object: MMCellModel?, indexPath: IndexPath, newIndexPath: IndexPath?) {
            self.type = type
            self.object = object
            self.indexPath = indexPath
            self.newIndexPath = newIndexPath
        }
    }
    private var _ups:[Node] = []
    
    public func ssn_controller(_ controller: AnyObject, didChange anObject: MMCellModel?, at indexPath: IndexPath?, for type: MMFetchChangeType, newIndexPath: IndexPath?) {
        if let indexPath = indexPath {
            _ups.append(Node(type:type,object:anObject,indexPath:indexPath,newIndexPath:newIndexPath))
        }
    }
    
    public func ssn_controllerWillChangeContent(_ controller: AnyObject) {
        _ups.removeAll()
    }
    
    public func ssn_controllerDidChangeContent(_ controller: AnyObject) {
        MMTry.try({
            self._table.performBatchUpdates({ [weak self] () in
                guard let sself = self else {return}
                for node in sself._ups {
                    switch node.type {
                    case .delete:
                        sself._table.deleteItems(at: [node.indexPath])
                    case .insert:
                        sself._table.insertItems(at: [node.indexPath])
                    case .update:
                        sself._table.reloadItems(at: [node.indexPath])
                    default:
                        if let newIndexPath = node.newIndexPath {
                            sself._table.deleteItems(at: [node.indexPath])
                            sself._table.insertItems(at: [newIndexPath])
                        }
                    }
                }
                }, completion: { [weak self] (b) in
                    guard let sself = self else {return}
                    sself._ups.removeAll()
            })
        }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
    }
    
    
    
    private var _layout:MMCollectionViewLayout!
    private var _table : UICollectionView!
    private var _fetchs : MMFetchsController<T>!
}

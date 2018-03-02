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
        
    }
    
    deinit {
        _table.dataSource = nil
        _table.delegate = nil
    }
    
    // MARK:- UITableViewDelegate代理
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("点击了\(indexPath.row) section:\(indexPath.section)")
        collectionView.deselectItem(at: indexPath, animated: false)
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
        //一次更新掉
        _table.performBatchUpdates({ [weak self] () in
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
    }
    
    private var _layout:MMCollectionViewLayout!
    private var _table : UICollectionView!
    private var _fetchs : MMFetchsController<T>!
}

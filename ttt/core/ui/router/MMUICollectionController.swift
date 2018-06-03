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
        _table.backgroundColor = UIColor.white
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
        _table?.dataSource = nil
        _table?.delegate = nil
    }
    
    // MARK:- UICollectionViewDelegate MMCollectionViewDelegate 代理
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    }
    
    public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    }
    
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
    
    func collectionView(_ collectionView: UICollectionView, insetsForCellAt indexPath: IndexPath) -> UIEdgeInsets {
        guard let m = _fetchs.object(at: indexPath) else {
            return UIEdgeInsets.zero
        }
        return m.ssn_cellInsets()
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
    public func ssn_controller(_ controller: AnyObject, deletes: ((_ section:Int) -> [IndexPath])?, inserts: ((_ section:Int) -> [IndexPath])?, updates: ((_ section:Int) -> [IndexPath])?, at section:Int) {
        let block:(_ updateUI:Bool) -> Void = { (updateUI) in
            
            if let deletes = deletes {
                let indexPaths = deletes(section)
                if updateUI && indexPaths.count > 0 {
                    self._table.deleteItems(at: indexPaths)
                }
            }
            
            if let inserts = inserts {
                let indexPaths = inserts(section)
                if updateUI && indexPaths.count > 0 {
                    self._table.insertItems(at: indexPaths)
                }
            }
            
            if let updates = updates {
                let indexPaths = updates(section)
                if updateUI && indexPaths.count > 0 {
                    self._table.reloadItems(at: indexPaths)
                }
            }
            
            if updateUI {
                self._table.reloadSections(IndexSet(integer: section))
            }
        }
        
        // 由于苹果对SupplementaryView动画支持有问题(局部更新动画更加不流畅，且导致图存crash)，只能采用无动画reload, 可查看：http://www.openradar.me/31749591
        /*if self._layout.config.floating {
            block(false)
            self._table.reloadData()
            return
        }*/
        
        MMTry.try({
            self._table.performBatchUpdates({
                block(true)
            }, completion: nil)
        }, catch: { (exception) in
            block(false)
            print("error:\(String(describing: exception))")
        }, finally: nil)
    }
    
    public func ssn_controllerWillChangeContent(_ controller: AnyObject) {}
    
    public func ssn_controllerDidChangeContent(_ controller: AnyObject) {}
    
    
    
    private var _layout:MMCollectionViewLayout!
    private var _table : UICollectionView!
    private var _fetchs : MMFetchsController<T>!
    /*lazy var noConnectionView:NoConnectionView = {
        let ViewSize = CGSize(width: self.view.width, height: 198)
        let noConnectionView = NoConnectionView(frame:CGRect(x:0, y: (self.view.height - ViewSize.height) / 2.5, width: ViewSize.width, height: ViewSize.height))
        noConnectionView.isHidden = true
        return noConnectionView
    }()*/
}

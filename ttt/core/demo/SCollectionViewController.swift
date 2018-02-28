//
//  SCollectionViewController.swift
//  ttt
//
//  Created by lingminjun on 2018/2/28.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit

class SCollectionViewController : MMUIController,UICollectionViewDelegate,UICollectionViewDataSource,MMCollectionViewDataSource,UIActionSheetDelegate {
    
    
    
    var _layout:MMCollectionViewLayout!
    var _table:UICollectionView!
    var _datas:[[Int]] = []
    
    
    //
    override func onLoadView() -> Bool {
        self.view = UIView(frame:UIScreen.main.bounds)
        self.view.backgroundColor = UIColor.white
        
        var config = LayoutConfig()
        config.floating = true
        config.columnCount = 2
        _layout = MMCollectionViewLayout(config)
        
        _table = UICollectionView(frame: self.view.bounds, collectionViewLayout: _layout)
        _table.dataSource = self
        _table.delegate = self
        _table.backgroundColor = UIColor.clear
        _table.alwaysBounceVertical = true
        self.view.addSubview(_table)
        
        return true
    }
    
    override func onViewDidLoad() {
        
        _table.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "CELLID")
        _table.register(UICollectionViewCell.self, forSupplementaryViewOfKind: COLLECTION_HEADER_KIND, withReuseIdentifier: "header")
        
        let item = UIBarButtonItem(title: "选项", style: UIBarButtonItemStyle.plain, target: self, action: #selector(SCollectionViewController.rightAction))
        self.navigationItem.rightBarButtonItem=item
        
        setupDataList()
    }
    
    @objc func rightAction() -> Void {
        let sheet = UIActionSheet(title: "选择", delegate: self, cancelButtonTitle: "取消", destructiveButtonTitle: nil)
        sheet.addButton(withTitle: "非固定行高")
        sheet.addButton(withTitle: "定高多列")
        sheet.addButton(withTitle: "多列飘浮")
        sheet.addButton(withTitle: "瀑布流")
        sheet.addButton(withTitle: "瀑布流飘浮")
        sheet.show(in: self.view)
    }
    
    override func onViewDidDisappear(_ animated: Bool) {
        
    }
    
    
    func setupDataList() {
        _datas.removeAll()
        if true {
            var list:[Int] = []
            let dataCount = arc4random()%25+30;
            for _ in 0..<dataCount {
                let rowHeight = arc4random()%100+30;
                list.append(Int(rowHeight))
            }
            _datas.append(list)
        }
        if true {
            var list:[Int] = []
            let dataCount = arc4random()%25+30;
            for _ in 0..<dataCount {
                let rowHeight = arc4random()%100+30;
                list.append(Int(rowHeight))
            }
            _datas.append(list)
        }
        
        _table.reloadData()
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return _datas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _datas[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, canFloatingCellAt indexPath: IndexPath) -> Bool {
        return indexPath.row % 7 == 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CELLID", for: indexPath)
//        if cell == nil {
//            cell = UICollectionViewCell()
//        }
        
        let red = Double(arc4random()%256)/255.0
        let green = Double(arc4random()%256)/255.0
        let blue = Double(arc4random()%256)/255.0
        
        cell.backgroundColor = UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
        
//        NSLog(@"cell indexpath = (%ld,%ld)",indexPath.section,indexPath.row);
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == COLLECTION_HEADER_KIND {
            var cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath)
//            if cell == nil {
//                cell = UICollectionViewCell()
//            }
            let red = Double(arc4random()%256)/255.0
            let green = Double(arc4random()%256)/255.0
            let blue = Double(arc4random()%256)/255.0
            cell.backgroundColor = UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: 1)
            return cell
        }
        
        var cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header1", for: indexPath)
//        if cell == nil {
//            cell = UICollectionViewCell()
//        }
        return cell
    }
}

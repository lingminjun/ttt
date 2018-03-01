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
    var _config:LayoutConfig = LayoutConfig()
    
    
    //
    override func onLoadView() -> Bool {
        self.view = UIView(frame:UIScreen.main.bounds)
        self.view.backgroundColor = UIColor.white
        
        _config.columnSpace = 6
        _config.rowDefaultSpace = 6
        _layout = MMCollectionViewLayout(_config)
        
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
        
//        self.automaticallyAdjustsScrollViewInsets = false
        
        setupDataList()
    }
    
    @objc func rightAction() -> Void {
        let sheet = UIActionSheet(title: "选择", delegate: self, cancelButtonTitle: "取消", destructiveButtonTitle: nil)
        sheet.addButton(withTitle: "非固定行高")
        sheet.addButton(withTitle: "定高多列")
        sheet.addButton(withTitle: "多列飘浮")
        sheet.addButton(withTitle: "瀑布流")
        sheet.addButton(withTitle: "瀑布流飘浮")
        sheet.addButton(withTitle: "重置数据")
        sheet.show(in: self.view)
    }
    
    func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
        let title = actionSheet.buttonTitle(at: buttonIndex)
        if title == "重置数据" {
            setupDataList()
            _table.reloadData()
            return
        }
        
        if title == "取消" {
            return
        }
        
        if title == "非固定行高" {
            _config.rowHeight = 0
            _config.columnCount = 1
            _config.floating = false
        }else if title == "定高多列" {
            _config.rowHeight = 44
            _config.columnCount = 3
            _config.floating = false
        } else if title == "多列飘浮" {
            _config.rowHeight = 44
            _config.columnCount = 2
            _config.floating = true
        } else if title == "瀑布流" {
            _config.rowHeight = 0
            _config.columnCount = 2
            _config.floating = false
        } else if title == "瀑布流飘浮" {
            _config.rowHeight = 0
            _config.columnCount = 2
            _config.floating = true
        }
        
        _layout.config = _config
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
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return _datas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _datas[section].count
    }
    
    func collectionView(_ collectionView: UICollectionView, spanSizeForCellAt indexPath: IndexPath) -> Int {
        return indexPath.row % 5 % 3
    }
    
    func collectionView(_ collectionView: UICollectionView, canFloatingCellAt indexPath: IndexPath) -> Bool {
        return indexPath.row % 7 == 0
    }
    
    func collectionView(_ collectionView: UICollectionView, heightForCellAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(_datas[indexPath.section][indexPath.row])
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("selcected indexPath(\(indexPath.row),\(indexPath.section))")
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

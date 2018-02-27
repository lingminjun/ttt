//
//  MMCollectionViewLayout.swift
//  ttt
//
//  Created by lingminjun on 2018/2/27.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import UIKit

let COLLECTION_HEADER_KIND = "Header"

struct LayoutConfig {
    var floating:Bool = false//存在某些cell飘浮，此选项开启，会造成性能损耗
    
    //默认UITable风格
    var columnCount:Int = 1
    var rowHeight:CGFloat = 44//固定行高(dp)，设置为0时，表示不固定行高；若设置大于零的有效值，则标识固定行高，不以委托返回高度计算
    var columnSpace:CGFloat = 1//(dp)
    var rowDefaultSpace:CGFloat = 1//默认行间距(dp)
    var insets:UIEdgeInsets = UIEdgeInsets.zero //header将忽略左右上下的间距，只有cell有效
}

@objc protocol MMCollectionViewDataSource : UICollectionViewDataSource {
    
    //可以漂浮停靠在界面顶部
    @objc optional func collectionView(_ collectionView: UICollectionView, canFloatingCellAt indexPath: IndexPath) -> Bool
    
    //cell的行高
    @objc optional func collectionView(_ collectionView: UICollectionView, heightForCellAt indexPath: IndexPath) -> CGFloat
    
    //cell是否SpanSize，返回值小于等于零时默认为1
    @objc optional func collectionView(_ collectionView: UICollectionView, spanSizeForCellAt indexPath: IndexPath) -> Int
    
}

//控制UICollect所有瀑布流，无section headerView和footerView支持，
class MMCollectionViewLayout: UICollectionViewLayout {
    private var _config:LayoutConfig = LayoutConfig()
    
    public init(_ config:LayoutConfig = LayoutConfig()) {
        super.init()
        _config = config;
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        fatalError("init(coder:) has not been implemented")
    }
    
    open var config:LayoutConfig {
        get { return _config; }
        set {
            _config = newValue
            if _config.columnCount <= 0 {//防止设置为非法数字
                _config.columnCount = 1
            }
            if _config.rowHeight < 0 {//防止设置为非法数字
                _config.rowHeight = 0
            }
            if _config.columnSpace < 0 {//防止设置为非法数字
                _config.columnSpace = 1
            }
            if _config.rowDefaultSpace < 0 {//防止设置为非法数字
                _config.rowDefaultSpace = 1
            }
            invalidateLayout()
        }
    }
    
//    weak fileprivate final var delegate: UICollectionViewDelegate? { get { return collectionView?.delegate } }
//    weak fileprivate final var collectionDataSource: UICollectionViewDataSource? { get { return collectionView?.dataSource } }
    weak fileprivate final var dataSource: MMCollectionViewDataSource? {
        get {
            guard let ds = self.collectionView?.dataSource else { return nil }
            if ds is MMCollectionViewDataSource {
                return ds as? MMCollectionViewDataSource
            }
            return nil
        }
    }
    
    
    //采用一次性布局
    private var _cellLayouts:[IndexPath:UICollectionViewLayoutAttributes] = [:]
    private var _headIndexs:[IndexPath] = [] //header形式
    private var _bottoms:[UInt] = []

    // 
    override func prepare() {
        super.prepare()
        
        //起始位计算
        _bottoms.removeAll()
        for _ in 0..<_config.columnCount {
            _bottoms.append(0)
        }
        _cellLayouts.removeAll();
        _headIndexs.removeAll();
        
        guard let view = self.collectionView else {
            return
        }
        
        let ds = self.dataSource
        let respondCanFloating = ds == nil ? false : ds!.responds(to: #selector(MMCollectionViewDataSource.collectionView(_:canFloatingCellAt:)))
        let respondHeightForCell = ds == nil ? false : ds!.responds(to: #selector(MMCollectionViewDataSource.collectionView(_:heightForCellAt:)))
        let respondSpanSize = ds == nil ? false : ds!.responds(to: #selector(MMCollectionViewDataSource.collectionView(_:spanSizeForCellAt:)))
        
        let floating = _config.floating
        let rowHeight = _config.rowHeight
        let columnCount = _config.columnCount
        
        let sectionCount = view.numberOfSections
        
        for section in 0..<sectionCount {
            
            let cellCount = view.numberOfItems(inSection: section);
            for row in 0..<cellCount {
                
                let indexPath = IndexPath(row: row, section: section)
                
                //是否漂浮
                var isFloating:Bool = false
                if floating && respondCanFloating {
                    isFloating = ds!.collectionView!(view, canFloatingCellAt: indexPath)
                }
                
                //行高
                var height:CGFloat = rowHeight
                if height == 0 && respondHeightForCell {
                    height = ds!.collectionView!(view, heightForCellAt: indexPath)
                }
            
                //占用各数
                var spanSize = 1
                if isFloating {//肯定是占满一行
                    spanSize = columnCount
                } else if columnCount > 1 && respondSpanSize {
                    spanSize = ds!.collectionView!(view, spanSizeForCellAt: indexPath)
                    if spanSize > columnCount {
                        spanSize = columnCount
                    }
                }
                
                //取布局属性对象
                var attributes:UICollectionViewLayoutAttributes!
                if isFloating {
                    attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: COLLECTION_HEADER_KIND, with: indexPath)
                } else {
                    attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)//layoutAttributesForCellWithIndexPath
                }
                _cellLayouts[indexPath] = attributes
                
                
                
                //仅仅支持sectionHeader
//                let attributes = UICollectionViewLayoutAttributes.layoutAttributes(supplementaryViewOfKind:COLLECTION_HEADER_KIND withIndexPath:indexPath)
//
//                if (attributes != nil) {
//                    [self.attributes setObject:attributes forKey:indexPath];
//                }
                
                //            NSInteger less = [self columnOfLessHeight];
                //            if (self.columnHeights[less].integerValue > screenBottom) {
                //                break;
                //            }
            }
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return _config.floating
    }
    
    
    fileprivate final var sectionOfLessHeight:Int {
        get {
            var minIndex:Int = 0
            for index in 1..<_config.columnCount {
                if _bottoms[index] < _bottoms[minIndex] {
                    minIndex = index
                }
            }
            return minIndex
        }
    }
    
    fileprivate final var sectionOfMostHeight:Int {
        get {
            var maxIndex:Int = 0
            for index in 1..<_config.columnCount {
                if _bottoms[index] > _bottoms[maxIndex] {
                    maxIndex = index
                }
            }
            return maxIndex
        }
    }
}

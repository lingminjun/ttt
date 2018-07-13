//
//  MMCollectionViewLayout.swift
//  ttt
//
//  Created by lingminjun on 2018/2/27.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import UIKit

let COLLECTION_HEADER_KIND = "Header"

let CELL_INSETS_TAG = "cell_content_insets"

public struct MMLayoutConfig {
    
    var scrollDirection:UICollectionViewScrollDirection = .vertical
    
    var floating:Bool = false//存在某些cell飘浮，此选项开启，会造成性能损耗
    var floatingOffsetY:CGFloat = -1 //存在cell飘浮时自定义offset起始位置；小于零表示采用默认
    
    //默认UITable风格，以下若属性命名均已vertical来命名，若设置horizontal时，则需要转换含义
    var columnCount:Int = 1
    var rowHeight:CGFloat = 44//固定行高(dp)，设置为0时，表示不固定行高；若设置大于零的有效值，则标识固定行高，不以委托返回高度计算
    var columnSpace:CGFloat = 1//(dp)
    var rowDefaultSpace:CGFloat = 1//默认行间距(dp)
    var insets:UIEdgeInsets = UIEdgeInsets.zero //header将忽略左右上下的间距，只有cell有效
    var supportMagicHorizontalEdge:Bool = false//横向魔法边距，只有当cell返回支持时展示
//    var magicVerticalEdge:CGFloat = 0//垂直魔法边距，只有当cell返回支持时展示

}

@objc protocol MMCollectionViewDelegate : UICollectionViewDelegate {
    
    //可以漂浮停靠在界面顶部
    @objc optional func collectionView(_ collectionView: UICollectionView, canFloatingCellAt indexPath: IndexPath) -> Bool
    
    //cell的行高,若scrollDirection == .horizontal则返回的是宽度，包含EdgeInsets.bottom+EdgeInsets.top的值
    @objc optional func collectionView(_ collectionView: UICollectionView, heightForCellAt indexPath: IndexPath) -> CGFloat
    
    //cell的内边距, floating cell不支持
    @objc optional func collectionView(_ collectionView: UICollectionView, insetsForCellAt indexPath: IndexPath) -> UIEdgeInsets
    
    //cell的魔法边距描述,floating cell不支持,
    @objc optional func collectionView(_ collectionView: UICollectionView, magicHorizontalEdgeForCellAt indexPath: IndexPath) -> CGFloat
    
    //cell是否SpanSize，返回值小于等于零时默认为1
    @objc optional func collectionView(_ collectionView: UICollectionView, spanSizeForCellAt indexPath: IndexPath) -> Int
    
}

//控制UICollect所有瀑布流，无section headerView和footerView支持，
class MMCollectionViewLayout: UICollectionViewLayout {
    private var _config:MMLayoutConfig = MMLayoutConfig()
    
    public init(_ config:MMLayoutConfig = MMLayoutConfig()) {
        super.init()
        _config = config
        if config.floatingOffsetY >= 0 {//表示不走默认情况
            setFloatingOffsetY(config.floatingOffsetY)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        fatalError("init(coder:) has not been implemented")
    }
    
    open var config:MMLayoutConfig {
        get { return _config; }
        set {
            let changOffset =  _config.floatingOffsetY != newValue.floatingOffsetY
            
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
            
            if changOffset {
                setFloatingOffsetY(_config.floatingOffsetY)
            }
            
//            guard let view = self.collectionView else {
//                invalidateLayout()
//                return
//            }
//            view.reloadData()
            invalidateLayout()
        }
    }
    
//    weak fileprivate final var delegate: UICollectionViewDelegate? { get { return collectionView?.delegate } }
//    weak fileprivate final var collectionDataSource: UICollectionViewDataSource? { get { return collectionView?.dataSource } }
    weak fileprivate final var delegate: MMCollectionViewDelegate? {
        get {
            guard let ds = self.collectionView?.delegate else { return nil }
            if ds is MMCollectionViewDelegate {
                return ds as? MMCollectionViewDelegate
            }
            return nil
        }
    }
    
    
    //采用一次性布局
    private var _cellLayouts:[IndexPath:UICollectionViewLayoutAttributes] = [:]
    private var _headIndexs:[IndexPath] = [] //header形式
    private var _bottoms:[CGFloat] = []

    // 准备布局
    override func prepare() {
        super.prepare()
        
        //起始位计算
        _bottoms.removeAll()
        if _config.columnCount > 0 {
            for _ in 0..<_config.columnCount {
                _bottoms.append(0.0)
            }
        } else {
            _bottoms.append(0.0)
        }
        _cellLayouts.removeAll();
        _headIndexs.removeAll();
        
        guard let view = self.collectionView else {
            return
        }
        
        var respondCanFloating = false
        var respondHeightForCell = false
        var respondInsetForCell = false
        var respondMagicEdgeForCell = false
        var respondSpanSize = false
        let ds = self.delegate
        if let ds = ds {
            respondCanFloating = ds.responds(to: #selector(MMCollectionViewDelegate.collectionView(_:canFloatingCellAt:)))
            respondHeightForCell = ds.responds(to: #selector(MMCollectionViewDelegate.collectionView(_:heightForCellAt:)))
            respondInsetForCell = ds.responds(to: #selector(MMCollectionViewDelegate.collectionView(_:insetsForCellAt:)))
            respondMagicEdgeForCell = ds.responds(to: #selector(MMCollectionViewDelegate.collectionView(_:magicHorizontalEdgeForCellAt:)))
            respondSpanSize = ds.responds(to: #selector(MMCollectionViewDelegate.collectionView(_:spanSizeForCellAt:)))
        }
        
        let floating = _config.floating
        let rowHeight = _config.rowHeight
        let columnCount = _config.columnCount
        let viewWidth = _config.scrollDirection == .vertical ? view.bounds.size.width : view.bounds.size.height
        let viewWidthInsets = _config.scrollDirection == .vertical ? (_config.insets.left + _config.insets.right) : (_config.insets.top + _config.insets.bottom)
        let floatingWidth = viewWidth

        let cellWidth = CGFloat(roundf(Float((viewWidth - viewWidthInsets - _config.columnSpace * CGFloat(columnCount - 1)) / CGFloat(columnCount))))
        let diffWidth = view.bounds.size.width - viewWidthInsets - _config.columnSpace * CGFloat(columnCount - 1) - cellWidth * CGFloat(columnCount)
        
        
        let sectionCount = view.numberOfSections
        
        for section in 0..<sectionCount {
            
            let cellCount = view.numberOfItems(inSection: section);
            for row in 0..<cellCount {
                
                let indexPath = IndexPath(row: row, section: section)
                
                //是否漂浮
                var isFloating:Bool = _config.floating && _config.scrollDirection == .vertical //水平暂时不支持停靠
                if let ds = ds, (floating && respondCanFloating) {
                    isFloating = ds.collectionView!(view, canFloatingCellAt: indexPath)
                }
                if isFloating {
                    _headIndexs.append(indexPath)
                }
                
                //行高
                var height:CGFloat = rowHeight
                if let ds = ds, ( height <= 0 && respondHeightForCell ) {
                    height = ds.collectionView!(view, heightForCellAt: indexPath)
                }
                
                //内边距
                var insets = UIEdgeInsets.zero
                if let ds = ds, !isFloating && respondInsetForCell {
                    insets = ds.collectionView!(view, insetsForCellAt: indexPath)
                }
                
            
                //占用各数
                var spanSize = 1
                if isFloating {//肯定是占满一行
                    spanSize = columnCount
                } else if let ds = ds, ( columnCount > 1 && respondSpanSize ) {
                    spanSize = ds.collectionView!(view, spanSizeForCellAt: indexPath)
                    if spanSize > columnCount {
                        spanSize = columnCount
                    } else if spanSize < 1 {
                        spanSize = 1
                    }
                }
                
                //取布局属性对象
                var attributes:UICollectionViewLayoutAttributes!
                if isFloating {
                    attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: COLLECTION_HEADER_KIND, with: indexPath)
                    attributes.zIndex = 1024
                } else {
                    attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)//layoutAttributesForCellWithIndexPath
                    attributes.ssn_setTag(CELL_INSETS_TAG, tag: insets)
                }
                _cellLayouts[indexPath] = attributes//记录下来，防止反复创建
                
                var suitableSetion = self.sectionOfLessHeight
                var y = _bottoms[suitableSetion] //起始位置，水平对应x值
                
                //说明当前位置并不合适,换到新的一行开始处理
                if isFloating || suitableSetion + spanSize > columnCount {
                    let mostSetion = self.sectionOfMostHeight
                    y = _bottoms[mostSetion] //起始位置
                    suitableSetion = 0 //new line
                } else if spanSize > 1 {//这种情况需要观察占用列的最高值
                    //取显示换位最长的
                    for index in suitableSetion..<(suitableSetion + spanSize) {
                        if y < _bottoms[index] {
                            y = _bottoms[index]
                        }
                    }
                }
                
                //y起始行特别处理
                if section == 0 && row == 0 && y == 0.0 && !isFloating {
                    y = y + (_config.scrollDirection == .vertical ? _config.insets.top : _config.insets.left)
                }
                
                //x起始位和宽度
                var x = (_config.scrollDirection == .vertical ? _config.insets.left : _config.insets.top) + (cellWidth + _config.columnSpace) * CGFloat(suitableSetion)
                var width = cellWidth * CGFloat(spanSize) + _config.columnSpace * CGFloat(spanSize - 1)
                //最后的宽度修正
                if diffWidth != 0 && abs(viewWidth - (x + width)) < abs(diffWidth) + 0.1 {
                    width = width + diffWidth
                }
                
                //对于floating,满行处理
                if isFloating {
                    x = 0
                    width = floatingWidth
                } else if let ds = ds, _config.supportMagicHorizontalEdge && _config.scrollDirection == .vertical && respondMagicEdgeForCell {// 魔法边距
                    let magic = ds.collectionView!(view, magicHorizontalEdgeForCellAt: indexPath)
                    if magic > 0 {
                        //左边 TODO : FIXME
                        if suitableSetion == 0 {
                            x = x + magic
                        }
                        
                        //重新计算行宽
                        let ncellWidth = CGFloat(roundf(Float((viewWidth - viewWidthInsets - (2 * magic) - _config.columnSpace * CGFloat(columnCount - 1)) / CGFloat(columnCount))))
                        width = ncellWidth * CGFloat(spanSize) + _config.columnSpace * CGFloat(spanSize - 1)
                    }
                }
                
                //最终位置
                if _config.scrollDirection == .vertical {
                    attributes.frame = CGRect(x:x + insets.left, y:y + insets.top, width:width - (insets.left + insets.right), height:height - (insets.top + insets.bottom))
                } else {
                    attributes.frame = CGRect(x:y + insets.left, y:x + insets.top, width:height - (insets.left + insets.right), height:width - (insets.top + insets.bottom))
                }
                
                //更新每列位置信息
                for index in suitableSetion..<(suitableSetion + spanSize) {
                    _bottoms[index] = y + height + _config.rowDefaultSpace
                }
            }
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        //存在飘浮cell
        let hasFloating = !_headIndexs.isEmpty
        
        var csets:Set<IndexPath> = Set<IndexPath>() //所有被列入的key
        var hsets:Set<IndexPath> = Set<IndexPath>() //所有被列入header的key
        var minCIndexPath:IndexPath? = nil
        var minHIndexPath:IndexPath? = nil
        
        //遍历所有 Attributes 看看哪些符合 rect
        var list:[UICollectionViewLayoutAttributes] = []
        _cellLayouts.forEach { (key,value) in
            var insets = UIEdgeInsets.zero
            if let sets = value.ssn_tag(CELL_INSETS_TAG) as? UIEdgeInsets {
                insets = sets
            }
            let frame = value.frame
            let oframe = CGRect(x: frame.origin.x - insets.left, y: frame.origin.y - insets.top, width: frame.size.width + insets.left + insets.right, height: frame.size.height + insets.top + insets.bottom)
            
            //存在交集
            if rect.intersects(oframe) {
                list.append(value)
                
                csets.insert(key)
                
                //记录正常情况下包含的set
                if hasFloating && value.representedElementKind == COLLECTION_HEADER_KIND {
                    
                    hsets.insert(key)
                    
                    //先还原布局
                    resetFloatingCellLayout(indexPath: key)
                    
                    //取最小位置的header
                    if minHIndexPath == nil || minHIndexPath! > key {
                        minHIndexPath = key
                    }
                } else {//取最小位置的cell
                    if minCIndexPath == nil || minCIndexPath! > key {
                        minCIndexPath = key
                    }
                }
            }
        }
        
        //没有飘浮处理，直接返回好了
        if !hasFloating {
            return list
        }
        
        
        if minHIndexPath == nil {
            if let minC = minCIndexPath, _headIndexs[0] < minC {
                minHIndexPath = _headIndexs[0]
                resetFloatingCellLayout(indexPath: _headIndexs[0])//先还原布局
            }
        }
        
        //往前寻找一个飘浮的cell
        if let minH = minHIndexPath, let minC = minCIndexPath, minC < minH {
            if let idx = _headIndexs.index(of: minH) {
                if idx > 0 {
                    minHIndexPath = _headIndexs[idx - 1]
                    resetFloatingCellLayout(indexPath: _headIndexs[idx - 1])//先还原布局
                }
            }
        }
        
        guard let minH = minHIndexPath else {
            return list
        }
        
        //设置飘浮状态
        setFloatingCellLayout(indexPath: minH,hsets: hsets, list: &list)
        
        return list
    }
    
    private var defaultAttributes:UICollectionViewLayoutAttributes!
    private func getDefaultAttributes(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        if defaultAttributes == nil {
            defaultAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            defaultAttributes.frame.size.height = 0
            defaultAttributes.isHidden = true
        }
        defaultAttributes.indexPath = indexPath
        return defaultAttributes!
    }
    
//    private var defaultHeadAttributes:UICollectionViewLayoutAttributes!
    private func getDefaultHeadAttributes(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        let defaultHeadAttributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: COLLECTION_HEADER_KIND, with: indexPath)
        defaultHeadAttributes.frame.size.height = 0
        defaultHeadAttributes.isHidden = true
        defaultHeadAttributes.indexPath = indexPath
        return defaultHeadAttributes
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = _cellLayouts[indexPath] else { return getDefaultHeadAttributes(at: indexPath) }
        if attributes.representedElementKind == COLLECTION_HEADER_KIND {//必须兼容返回一个default的布局
            return getDefaultHeadAttributes(at: indexPath)
        } else {
            return attributes
        }
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = _cellLayouts[indexPath] else { return getDefaultAttributes(at: indexPath) }
        if attributes.representedElementKind == COLLECTION_HEADER_KIND {
            return attributes
        } else {
            return getDefaultAttributes(at: indexPath)
        }
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return _config.floating && _config.scrollDirection == .vertical
    }
    
    override var collectionViewContentSize: CGSize {
        get {
            guard let view = self.collectionView else {
                return CGSize.zero
            }
            let width = _config.scrollDirection == .vertical ? view.bounds.size.width : (_config.insets.left + _config.insets.right + _bottoms[self.sectionOfMostHeight])
            let height = _config.scrollDirection == .vertical ? (_config.insets.top + _config.insets.bottom + _bottoms[self.sectionOfMostHeight]) : view.bounds.size.height
            
            // self.navigationController.navigationBar.isTranslucent
            
            return CGSize(width:width,height:height)
        }
    }
    
    //设置飘浮位置
    fileprivate final func setFloatingCellLayout(indexPath:IndexPath,hsets:Set<IndexPath>, list:inout [UICollectionViewLayoutAttributes]) {
        guard let view = self.collectionView else {
            return
        }
        
        guard let value = _cellLayouts[indexPath] else { return }
        if !hsets.contains(indexPath) {
            list.append(value)
        }
        
        let frame = value.frame
        var insets = UIEdgeInsets.zero
        if let sets = value.ssn_tag(CELL_INSETS_TAG) as? UIEdgeInsets {
            insets = sets
        }
        var oframe = CGRect(x: frame.origin.x - insets.left, y: frame.origin.y - insets.top, width: frame.size.width + insets.left + insets.right, height: frame.size.height + insets.top + insets.bottom)
        
        let offsetY = originOffsetY + view.contentOffset.y + view.contentInset.top //基准线
        if offsetY < oframe.origin.y {
            return
        }
        
        //调整最靠近offsetY的基准线的cell需要调整
        var nextHeightTop = offsetY + 2*UIScreen.main.bounds.height //下一个head的头，默认值设置得比较大
        if indexPath != _headIndexs.last {//不等于最后一个,取下一个header的顶部
            if let next = _headIndexs.index(of: indexPath) {
                if let nextValue = _cellLayouts[_headIndexs[(next + 1)]] {
                    nextHeightTop = nextValue.frame.origin.y
                }
            }
        }
        
        oframe.origin.y = min(nextHeightTop - oframe.size.height, offsetY)
        
        //说明已经隐藏在停靠点内，不再需要修改布局，而是计算下一个header
        if oframe.origin.y + oframe.size.height <= offsetY {
            if let next = _headIndexs.index(of: indexPath) {
                if next + 1 < _headIndexs.count {
                    setFloatingCellLayout(indexPath: _headIndexs[next + 1], hsets: hsets, list: &list)
                }
            }
        } else {
            value.frame = CGRect(x: oframe.origin.x + insets.left, y: oframe.origin.y + insets.top, width: oframe.size.width - (insets.left + insets.right), height: oframe.size.height - (insets.top + insets.bottom))
        }
    }
    
    fileprivate final func resetFloatingCellLayout(indexPath:IndexPath) {
        guard let attributes = _cellLayouts[indexPath] else {
            return
        }
        
        let frame = attributes.frame
        var insets = UIEdgeInsets.zero
        if let sets = attributes.ssn_tag(CELL_INSETS_TAG) as? UIEdgeInsets {
            insets = sets
        }
        var oframe = CGRect(x: frame.origin.x - insets.left, y: frame.origin.y - insets.top, width: frame.size.width + insets.left + insets.right, height: frame.size.height + insets.top + insets.bottom)
        
        if indexPath.section == 0 && indexPath.row == 0 {
            oframe.origin.y = 0
        } else {
            var next:IndexPath? = IndexPath(row:indexPath.row + 1,section:indexPath.section)
            if !_cellLayouts.keys.contains(next!) {
                next = IndexPath(row:0,section:indexPath.section + 1)
                if !_cellLayouts.keys.contains(next!) {
                    next = nil
                }
            }
            
            //重新布局下header
            if let next = next {
                if let nextValue = _cellLayouts[next] {
                    if let insets = nextValue.ssn_tag(CELL_INSETS_TAG) as? UIEdgeInsets {
                        oframe.origin.y = nextValue.frame.origin.y + insets.top - _config.rowDefaultSpace - oframe.height
                    } else {
                        oframe.origin.y = nextValue.frame.origin.y - _config.rowDefaultSpace - oframe.height
                    }
                }
            }
        }
        attributes.frame = CGRect(x: oframe.origin.x + insets.left, y: oframe.origin.y + insets.top, width: oframe.size.width - (insets.left + insets.right), height: oframe.size.height - (insets.top + insets.bottom))
    }
    
//    weak var _cview:UICollectionView? = nil
//    override open var collectionView: UICollectionView? {
//        get { return _cview == nil ? super.collectionView : _cview }
//        set {
//            _cview = newValue
//            if newValue != nil {
//                _offsetY = newValue!.bounds.origin.y
//            }
//        }
//    }
    
    var _setedOffsetY = false
    var _offsetY:CGFloat = 0.0
    
    fileprivate final func setFloatingOffsetY(_ offsetY:CGFloat) {
        if offsetY < 0 {
            _setedOffsetY = false
            _offsetY = 0
        } else {
            _setedOffsetY = true
            _offsetY = offsetY
        }
    }
    
    //原点的offset位置
    fileprivate final var originOffsetY:CGFloat {
        get {
            if _setedOffsetY {
                return _offsetY
            }

            guard let view = self.collectionView else {
                return _offsetY
            }
            
            if #available(iOS 11.0, *) {//高于 iOS 11.0
//                _setedOffsetY = true
                return view.adjustedContentInset.top
            } else { //低于 iOS 11.0
                /*
                guard let superview = view.superview else {
                    return _offsetY
                }
                var responder = superview.next
                var vcontroller:UIViewController? = nil
                while responder != nil {
                    if let res = responder as? UIViewController {
                        _setedOffsetY = true
                        vcontroller = res
                        break
                    } else if responder is UIWindow {
                        _setedOffsetY = true
                        return _offsetY
                    }
                    responder = responder?.next
                }
                
                guard let vc = vcontroller else {
                    return _offsetY
                }
                
                _setedOffsetY = true
                
                //@available(iOS, introduced: 7.0, deprecated: 11.0, message: "Use UIScrollView's contentInsetAdjustmentBehavior instead")
                if vc.automaticallyAdjustsScrollViewInsets {
                    //ios 7.0
                    if !UIApplication.shared.isStatusBarHidden && !vc.prefersStatusBarHidden {
                        _offsetY = _offsetY + UIApplication.shared.statusBarFrame.height
                    }

                    if let nv = vc.navigationController, !nv.isNavigationBarHidden {
                        _offsetY = _offsetY + nv.navigationBar.frame.size.height
                    }
                }
                */
                return _offsetY
                
            }
        }
    }
    
    fileprivate final var sectionOfLessHeight:Int {
        get {
            var minIndex:Int = 0
            if (_config.columnCount > 1) {
                for index in 1..<_config.columnCount {
                    if _bottoms[index] < _bottoms[minIndex] {
                        minIndex = index
                    }
                }
            }
            return minIndex
        }
    }
    
    fileprivate final var sectionOfMostHeight:Int {
        get {
            var maxIndex:Int = 0
            if (_config.columnCount > 1) {
                for index in 1..<_config.columnCount {
                    if _bottoms[index] > _bottoms[maxIndex] {
                        maxIndex = index
                    }
                }
            }
            return maxIndex
        }
    }
}

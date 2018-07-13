//
//  DIFF.swift
//  ttt
//
//  Created by lingminjun on 2018/7/11.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

//diff 算法命名空间
public final class Diff {
    
    //Step操作
    public enum Operation {
        /// 无变化
        case nan
        /// 插入
        case insert
        /// 删除
        case delete
    }
    
    // diff 结果操作集
    public final class Step<T: Collection> {
        // from 原始结果集，当type == insert时，from为NULL
        public var from:T.Iterator.Element? = nil
        // to 目标结果集，当type == delete时，to为NULL
        public var to:T.Iterator.Element? = nil
        // f_idx 原始结果集位置
        public var fromIndex:Int = -1
        // t_idx 目标结果集位置
        public var toIndex:Int = -1
        // type 元素对应的变化
        public var operation:Diff.Operation = .nan
        
        public init() {}
        
        public init(delete:T.Iterator.Element, index:Int) {
            self.from = delete
            self.fromIndex = index
            self.operation = .delete
        }
        
        public init(insert:T.Iterator.Element, index:Int) {
            self.to = insert
            self.toIndex = index
            self.operation = .insert
        }
        
        public init(from:T.Iterator.Element, findex:Int, to:T.Iterator.Element, tindex:Int) {
            self.from = from
            self.fromIndex = findex
            self.to = to
            self.toIndex = tindex
            self.operation = .nan
        }
    }
   
    // 元素比较函数
    public typealias Eval<T: Collection> = (_ from:T.Iterator.Element, _ to:T.Iterator.Element) -> Bool
    
    //计算diff
    public static func diff<T: Collection>(_ from:T, _ to:T, eval:Diff.Eval<T>) -> [Diff.Step<T>] {
        var result:[Diff.Step<T>] = []
        //没有数据
        if from.isEmpty && to.isEmpty {
            return result
        }
        
        //特殊场景处理
        if to.isEmpty {//仅仅删除
            var idx = 0
            for e in from {
                result.append(Diff.Step<T>(delete: e, index: idx))
                idx = idx + 1
            }
            return result
        } else if from.isEmpty {//仅仅插入
            var idx = 0
            for e in to {
                result.append(Diff.Step<T>(insert: e, index:idx))
                idx = idx + 1
            }
            return result
        }
        
        let table = lcs(from, to, eval: eval)
        
        //ssn_diff_results_enumerate(table, from, to, eval:eval, result:&result)
        
        ssn_diff_results_enumerate_v2(table, from, to, eval:eval, result:&result)
        
        table.deallocate()
        
        return result
    }
}

extension Collection {
    // 集合方法支持
    public func ssn_diff(_ to:Self, eval:Diff.Eval<Self>) -> [Diff.Step<Self>] {
        return Diff.diff(self, to, eval: eval)
    }
    
    fileprivate func ssn_get(_ index: Int) -> Iterator.Element {
        return self[self.index(startIndex, offsetBy: index)]
    }
}

extension Diff {
    fileprivate static func ssn_diff_table_value(_ table:UnsafeMutablePointer<Int>,_ row:size_t,_ col:size_t,_ table_col:size_t) -> Int {
        return table.advanced(by: row * table_col + col).pointee
    }
    
    fileprivate static func ssn_diff_table_value_set(_ table:UnsafeMutablePointer<Int>,_ row:size_t,_ col:size_t,_ table_col:size_t,_ value:size_t) {
        table.advanced(by: row * table_col + col).initialize(to: value)
    }
    
    //动态规划，算出矩阵变化
    fileprivate static func lcs<T: Collection>(_ from:T, _ to:T, eval:Diff.Eval<T>) -> UnsafeMutablePointer<Int> {
        let rowSize = from.count + 1
        let colSize = to.count + 1
        
        var value0:Int = 0
        var value1:Int = 0
        var value2:Int = 0
        
        let table =  UnsafeMutablePointer<Int>.allocate(capacity: rowSize * colSize)
        table.assign(repeating: 0, count: rowSize * colSize) //初始化零
        
        
        for row in 1..<rowSize {
            for col in 1..<colSize {
                
                value0 = ssn_diff_table_value(table, row - 1, col - 1, colSize)
                value1 = ssn_diff_table_value(table, row, col - 1, colSize)
                value2 = ssn_diff_table_value(table, row - 1, col, colSize)
                
                if eval(from.ssn_get(row - 1), to.ssn_get(col - 1)) {//可能成为瓶颈
                    ssn_diff_table_value_set(table, row, col, colSize, (value0 + 1))
                } else if (value1 >= value2) {
                    ssn_diff_table_value_set(table, row, col, colSize, value1)
                } else {
                    ssn_diff_table_value_set(table, row, col, colSize, value2)
                }
            }
        }
        
        return table
    }
    
    //不断压栈，防止栈溢出，此处逻辑需要改，递归不是很好的做法
    fileprivate static func ssn_diff_results_enumerate<T: Collection>(_ table:UnsafeMutablePointer<Int>, _ from:T, _ to:T, _ row:size_t, _ col:size_t, eval:Diff.Eval<T>, result:inout [Diff.Step<T>]) {
        let colSize = to.count + 1
        
        var value0:Int = 0
        var value1:Int = 0
        var value2:Int = 0
        
        value0 = ssn_diff_table_value(table, row, col, colSize)
        value1 = ssn_diff_table_value(table, row, col - 1, colSize)
        value2 = ssn_diff_table_value(table, row - 1, col, colSize)
        
        if row > 0 && col > 0 && value1 == value2 && value0 > value1 {
            ssn_diff_results_enumerate(table, from, to, row - 1, col - 1, eval:eval, result:&result)
            result.append( Diff.Step<T>(from: from.ssn_get(row - 1), findex: row - 1, to: to.ssn_get(col - 1), tindex: col - 1) )
            //printf("  %c\n",s1[row - 1]);
        } else if col > 0 && (row == 0 || value1 >= value2) {
            ssn_diff_results_enumerate(table, from, to, row, col - 1, eval:eval, result:&result)
            result.append( Diff.Step<T>(insert: to.ssn_get(col - 1), index: col - 1) )
            //printf("+ %c\n",s2[col - 1]);
        }
        else if (row > 0 && (col == 0 || value1 < value2)) {
            ssn_diff_results_enumerate(table, from, to, row - 1, col, eval:eval, result:&result)
            result.append( Diff.Step<T>(delete: from.ssn_get(row - 1), index: row - 1) )
            //printf("- %c\n",s1[row - 1]);
        }
    }
    
    //算法待优化//2015-3-13，用空间转换，内存转移到堆中
    fileprivate static func ssn_diff_results_enumerate_v2<T: Collection>(_ table:UnsafeMutablePointer<Int>, _ from:T, _ to:T, eval:Diff.Eval<T>, result:inout [Diff.Step<T>]) {
        
        var value0:Int = 0
        var value1:Int = 0
        var value2:Int = 0
        
        //游标
//        let rowSize = from.count + 1
        let colSize = to.count + 1
        var row = from.count
        var col = to.count
        
        // 从表格末端开始，从后往前
        while (row > 0 || col > 0) {
            
            //从table中取规划值
            value0 = ssn_diff_table_value(table, row, col, colSize)
            value1 = ssn_diff_table_value(table, row, col - 1, colSize)
            value2 = ssn_diff_table_value(table, row - 1, col, colSize)
            
            if (row > 0 && col > 0 && value1 == value2 && value0 > value1) {
                row = row - 1
                col = col - 1
                result.insert(Diff.Step<T>(from: from.ssn_get(row), findex: row, to: to.ssn_get(col), tindex: col), at: 0)
            } else if (col > 0 && (row == 0 || value1 >= value2)) {
                col = col - 1
                result.insert(Diff.Step<T>(insert: to.ssn_get(col), index: col), at: 0)
            } else if (row > 0 && (col == 0 || value1 < value2)) {
                row = row - 1
                result.insert( Diff.Step<T>(delete: from.ssn_get(row), index: row), at: 0 )
            }
        }
    }
}


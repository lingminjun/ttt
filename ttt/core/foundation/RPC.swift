//
//  RPC.swift
//  ttt
//
//  Created by lingminjun on 2018/1/21.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

public protocol Feedback {
    func start(group:String)
    func finish(group:String, assembly:AnyObject)
    func failed(index:RPC.Index, cmd:String?, group:String, error: NSError)
    func staged(index:RPC.Index, cmd:String?, group:String, obj: AnyObject?, assembly:AnyObject) //Stage success.
}

/// 任务队列管理
/// 1. 并发队列
/// 2.1 顺序队列，FIFO，忽略错误，终断
/// 2.2 顺序队列，LIFO，not support, meaningless
/// 3. 量子队列
public final class RPC {
    //mark task index; convenient used, FIRST, SECOND, THIRD, FOURTH, FIFTH, SIXTH, SEVENTH, EIGHTH, NINTH, TENTH
    public enum Index {
        case first, second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth
        case at(Int)
        
        var value:Int { get {
            switch self {
            case .first: return 1
            case .second: return 2
            case .third: return 3
            case .fourth: return 4
            case .fifth: return 5
            case .sixth: return 6
            case .seventh: return 7
            case .eighth: return 8
            case .ninth: return 9
            case .tenth: return 10
            case .at(let value): return value
            } }
        }
        
        public init(_ index: Int) {
            if index == 1 {
                self = .first
            } else if index == 2 {
                self = .second
            } else if index == 3 {
                self = .third
            } else if index == 4 {
                self = .fourth
            } else if index == 5 {
                self = .fifth
            } else if index == 6 {
                self = .sixth
            } else if index == 7 {
                self = .seventh
            } else if index == 8 {
                self = .eighth
            } else if index == 9 {
                self = .ninth
            } else if index == 10 {
                self = .tenth
            } else {
                self = .at(index)
            }
        }
    }
    
    /// queue model
    public enum QueueModel {
        case concurrent,serial,discrete
    }
    
    /// result struct
    public enum Result {
        case value(AnyObject)
        case error(NSError)
    }
    
    /// assemble object: Need to be combined to get the data
    public class AssemblyObject {
        public var model:AnyObject? = nil
        private var resp:Dictionary<Int,Result> = Dictionary<Int,Result>()
        
        /// has done remote call
        public func hasDone(_ idx:Index) -> Bool {
            return resp.keys.contains(idx.value)
        }
        
        public func getResult(_ idx:Index) -> AnyObject? {
            guard let obj = resp[idx.value] else {return nil}
            
            switch obj {
            case Result.value(let v): return v
            default: break }
            
            return nil
        }
        
        public func getError(_ idx:Index) -> NSError? {
            guard let obj = resp[idx.value] else {return nil}
            
            switch obj {
            case Result.error(let e): return e
            default: break }
            
            return nil
        }
    }
    
    /// function
    public typealias AtomicBlock = (_ index:Index, _ cmd:String?, _ assembly:AssemblyObject) throws -> AnyObject
    
    // task
    fileprivate struct Task {
        var block: AtomicBlock!
        var cmd = "" //命令
        var level = 0 //安全级别，可以根据此标识定义特定安全访问价签属性
        var errbreak = false //线性时起作用
        var depend: [String]? = nil
    }
    
//    public static func aprint(_ items: Any...) {
//        print(items)
//    }
    
    public static func exec(blocks: [AtomicBlock], queue model:QueueModel = .concurrent, errbreak:Bool = false, group:String = "", feedback:Feedback) {
        switch model {
        case .concurrent:
            break
        case .serial:
            serialExec(blocks: blocks, errbreak: errbreak, group: group, feedback: feedback)
            break
        default:
            break
        }
    }
    
    private static func concurrentExec(blocks: [AtomicBlock], errbreak:Bool = false, group:String = "", feedback:Feedback) {
        var groupId = group
        if group.isEmpty {
            groupId = "\(Int(Date().timeIntervalSince1970))"
        }
        
        let cmd: String? = nil
        
        workQueue.async {
            DispatchQueue.main.async { feedback.start(group: groupId) }
            
            var assembly = AssemblyObject()
            for i in 0..<blocks.count {
                let idx = Index(i+1)
                let block = blocks[i]
                
                workQueue.async {
                    var rs: AnyObject? = nil
                    MMTry.try({ do {
                        rs = try block(idx, nil, assembly)
                        DispatchQueue.main.async { feedback.staged(index: idx, cmd: cmd, group: groupId, obj: rs, assembly: assembly) }
                    } catch {
                        DispatchQueue.main.async {
                            let err = NSError.init(domain: "RPC", code: -100, userInfo: [NSLocalizedDescriptionKey:error.localizedDescription])
                            feedback.failed(index: idx, cmd: cmd, group: groupId, error: err)
                        } } }, catch: { (exception) in
                            DispatchQueue.main.async {
                                let err = NSError.init(domain: "RPC", code: -100, userInfo: [NSLocalizedDescriptionKey:exception?.reason])
                                feedback.failed(index: idx, cmd: cmd, group: groupId, error: err)
                            }
                    }, finally: nil)
                }
            }
            
            DispatchQueue.main.async { feedback.finish(group: groupId, assembly: assembly) }
        }
    }
    
    private static func serialExec(blocks: [AtomicBlock], errbreak:Bool = false, group:String = "", feedback:Feedback) {
        var groupId = group
        if group.isEmpty {
            groupId = "\(Int(Date().timeIntervalSince1970))"
        }
        
        let cmd: String? = nil
        
        workQueue.async {
            
            DispatchQueue.main.async { feedback.start(group: groupId) }
            
            var assembly = AssemblyObject()
            
            for i in 0..<blocks.count {
                let idx = Index(i+1)
                let block = blocks[i]
                
                var rs: AnyObject? = nil
                MMTry.try({ do {
                    rs = try block(idx, nil, assembly)
                    DispatchQueue.main.async { feedback.staged(index: idx, cmd: cmd, group: groupId, obj: rs, assembly: assembly) }
                } catch {
                    DispatchQueue.main.async {
                        let err = NSError.init(domain: "RPC", code: -100, userInfo: [NSLocalizedDescriptionKey:error.localizedDescription])
                        feedback.failed(index: idx, cmd: cmd, group: groupId, error: err)
                    } } }, catch: { (exception) in
                        DispatchQueue.main.async {
                            let err = NSError.init(domain: "RPC", code: -100, userInfo: [NSLocalizedDescriptionKey:exception?.reason])
                            feedback.failed(index: idx, cmd: cmd, group: groupId, error: err)
                        }
                }, finally: nil)
            }
            
            DispatchQueue.main.async { feedback.finish(group: groupId, assembly: assembly) }
        }
    }
    
    // workQueue
    private static let workQueue = DispatchQueue(label: "com.mm.rpc.queue", qos: DispatchQoS.background)
    
    init(_ quque:DispatchQueue, discrete: Bool = false, max size:Int = 6, interval:Int = 100) {
        _queue = quque
        _maxSize = size
        _interval = interval
    }
    
    var _queue:DispatchQueue!
    var _maxSize:Int = 6
    var _interval:Int = 100 // (ms)
//    var _discrete = false
}

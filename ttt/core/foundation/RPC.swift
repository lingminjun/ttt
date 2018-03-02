//
//  RPC.swift
//  ttt
//
//  Created by lingminjun on 2018/1/21.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

public protocol Feedback {
    func start(group:String, assembly:RPC.AssemblyObject)
    func finish(group:String, assembly:RPC.AssemblyObject)
    func failed(index:RPC.Index, cmd:String, group:String, error: NSError)
    func staged(index:RPC.Index, cmd:String, group:String, result: Any, assembly:RPC.AssemblyObject) //Stage success.
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
            case .first: return 0
            case .second: return 1
            case .third: return 2
            case .fourth: return 3
            case .fifth: return 4
            case .sixth: return 5
            case .seventh: return 6
            case .eighth: return 7
            case .ninth: return 8
            case .tenth: return 9
            case .at(let value): return value
            } }
        }
        
        public init(_ index: Int) {
            if index == 0 {
                self = .first
            } else if index == 1 {
                self = .second
            } else if index == 2 {
                self = .third
            } else if index == 3 {
                self = .fourth
            } else if index == 4 {
                self = .fifth
            } else if index == 5 {
                self = .sixth
            } else if index == 6 {
                self = .seventh
            } else if index == 7 {
                self = .eighth
            } else if index == 8 {
                self = .ninth
            } else if index == 9 {
                self = .tenth
            } else {
                self = .at(index)
            }
        }
    }
    
    /// queue model
    public enum QueueModel {
        case concurrent,serial/*,discrete*/
    }
    
    /// result struct
    public enum Result {
        case value(Any)
        case error(NSError)
        case empty
    }
    
    /// returned datas
    public final class Response {
        private var _resp:Dictionary<Int,Result>!
        private var _cmds:[String]!
        
        fileprivate init(cmds:[String]) {
            _cmds = cmds
            // important! set minimumCapacity, because multi-thread set/get the dictionary
            _resp = Dictionary<Int,Result>(minimumCapacity: cmds.count + 3)
        }
        
        fileprivate func index(of cmd:String) -> Int? {
            for i in 0..<_cmds.count {
                if _cmds[i] == cmd {
                    return i
                }
            }
            return nil
        }
        
        /// has done remote call
        public func hasDone(_ idx:Index) -> Bool {
            return _resp.keys.contains(idx.value)
        }
        
        /// get result
        public func getResult<T>(_ idx:Index, type:T.Type) -> T? {
            guard let obj = _resp[idx.value] else {return nil}
            
            switch obj {
            case Result.value(let v): return v as? T
            default: break }
            
            return nil
        }
        
        /// is empty
        public func isEmpty(_ idx:Index) -> Bool {
            guard let obj = _resp[idx.value] else {return false}
            
            switch obj {
            case Result.empty: return true
            default: break }
            
            return false
        }
        
        /// get error
        public func getError(_ idx:Index) -> NSError? {
            guard let obj = _resp[idx.value] else {return nil}
            
            switch obj {
            case Result.error(let e): return e
            default: break }
            
            return nil
        }
        
        /// has done remote call
        public func hasDone(cmd:String) -> Bool {
            guard let idx = index(of: cmd) else { return true }
            return hasDone(RPC.Index(idx))
        }
        
        /// get result
        public func getResult<T>(cmd:String, type:T.Type) -> T? {
            guard let idx = index(of: cmd) else { return nil }
            return getResult(RPC.Index(idx),type:type)
        }
        
        /// is empty
        public func isEmpty(cmd:String) -> Bool {
            guard let idx = index(of: cmd) else { return true }
            return isEmpty(RPC.Index(idx))
        }
        
        /// get error
        public func getError(cmd:String) -> NSError? {
            guard let idx = index(of: cmd) else { return nil }
            return getError(RPC.Index(idx))
        }
        
        fileprivate func set(result:Any, index:Index) {
            if let rt = result as? Result {
                _resp[index.value] = rt
            } else {
                _resp[index.value] = Result.value(result)
            }
        }
        
        fileprivate func set(error:NSError, index:Index) {
            _resp[index.value] = Result.error(error)
        }
        
        fileprivate func setEmpty(index:Index) {
            _resp[index.value] = Result.empty
        }
    }
    
    /// assemble object: Need to be combined to get the data. you can modify the model in main thread
    public final class AssemblyObject {
        private var _model:Any? = nil
        private var _resp:Response!
        
        fileprivate init(resp:Response) {
            _resp = resp
        }
        
        /// get and set the complex object
        public func setModel(_ model: Any) { _model = model }
        public func getModel<T>(_ type:T.Type) -> T? {
            return _model as? T
        }
        
        /// get response
        public var resp: Response { get { return _resp } }
    }
    
    /// function
    public typealias AtomicTask = (_ index:Index, _ cmd:String?, _ resp:Response) throws -> Any

    /// exec single block
    public static func exec(task:@escaping AtomicTask, feedback:Feedback) {
        exec(cmds: [(task:task,cmd:"")], queue:.serial, feedback: feedback)
    }
    
    /// exec single block
    public static func exec(_ cmd:(task:AtomicTask,cmd:String), feedback:Feedback) {
        exec(cmds: [cmd], queue:.serial, feedback: feedback)
    }
    
    /// exec cmds
    public static func exec(tasks:[AtomicTask], queue model:QueueModel = .concurrent, errbreak:Bool = false, group:String = "", feedback:Feedback) {
        var list = [(task:AtomicTask,cmd:String)]()
        for i in 0..<tasks.count {
            let task = tasks[i]
            list.append((task: task, cmd: "cmd\(i)"))
        }
        exec(cmds: list, queue:model, errbreak:errbreak, group:group, feedback: feedback)
    }
    
    /// exec cmds
    public static func exec(cmds: [(task:AtomicTask,cmd:String)], queue model:QueueModel = .concurrent, errbreak:Bool = false, group:String = "", feedback:Feedback) {
        switch model {
        case .concurrent:
            concurrentExec(cmds: cmds, group: group, feedback: feedback)
            break
        case .serial:
            serialExec(cmds: cmds, errbreak: errbreak, group: group, feedback: feedback)
            break
        }
    }
    
    private static func tidyGrouId(_ group:String) -> String {
        var groupId = group
        if group.isEmpty {
            groupId = "\(Int(Date().timeIntervalSince1970 * 1000))"
        }
        return groupId
    }
    
    private static func tidyCMDs(_ cmds:[(task:AtomicTask,cmd:String)]) -> [String] {
        var cs = [String]()
        for i in 0..<cmds.count {
            let (_,cmd) = cmds[i]
            if cmd.isEmpty {
                cs.append("cmd\(i)")
            } else {
                cs.append(cmd)
            }
        }
        return cs
    }
    
    private static func concurrentExec(cmds: [(task:AtomicTask,cmd:String)], group:String = "", feedback:Feedback) {
        let groupId = tidyGrouId(group)
        
        DispatchQueue.global().async {
            let cs = tidyCMDs(cmds)
            let resp = Response(cmds:cs)
            let assembly = AssemblyObject(resp:resp)
            
            DispatchQueue.main.async { feedback.start(group: groupId, assembly: assembly) }
            
            let workGroup = DispatchGroup()
            
            for i in 0..<cmds.count {
                let idx = Index(i)
                let (block,_) = cmds[i]
                let cmd = cs[i]
                
                workQueue.async(group:workGroup) {
                    MMTry.try({ do {
                        let rs = try block(idx, nil, assembly.resp)
                        assembly.resp.set(result: rs, index: idx) // maybe not safty
                        DispatchQueue.main.async { feedback.staged(index: idx, cmd: cmd, group: groupId, result: rs, assembly: assembly) }
                    } catch {
                        let err = NSError(domain: "RPC", code: -101, userInfo: [NSLocalizedDescriptionKey:error.localizedDescription])
                        assembly.resp.set(error:err, index:idx)
                        DispatchQueue.main.async {
                            feedback.failed(index: idx, cmd: cmd, group: groupId, error: err)
                        } } }, catch: { (exception) in
                            var msg = "not message"
                            if let tmsg = exception?.reason {
                                msg = tmsg
                            }
                            let err = NSError(domain: "RPC", code: -102, userInfo: [NSLocalizedDescriptionKey:msg])
                            assembly.resp.set(error:err, index:idx)
                            DispatchQueue.main.async {
                                feedback.failed(index: idx, cmd: cmd, group: groupId, error: err)
                            }
                    }, finally: nil)
                }
            }
            
            workGroup.notify(queue: DispatchQueue.main) {
                feedback.finish(group: groupId, assembly: assembly)
            }
        }
    }
    
    private static func serialExec(cmds: [(task:AtomicTask,cmd:String)], errbreak:Bool = false, group:String = "", feedback:Feedback) {
        let groupId = tidyGrouId(group)
        
        workQueue.async {
            let cs = tidyCMDs(cmds)
            let resp = Response(cmds:cs)
            let assembly = AssemblyObject(resp:resp)
            
            DispatchQueue.main.async { feedback.start(group: groupId, assembly: assembly) }
            
            for i in 0..<cmds.count {
                let idx = Index(i)
                let (block,_) = cmds[i]
                let cmd = cs[i]
                
                var isError = false
                MMTry.try({ do {
                    let rs = try block(idx, nil, assembly.resp)
                    assembly.resp.set(result: rs, index: idx) // maybe not safty
                    DispatchQueue.main.async {
                        feedback.staged(index: idx, cmd: cmd, group: groupId, result: rs, assembly: assembly)
                    }
                } catch {
                    isError = true
                    let err = NSError(domain: "RPC", code: -101, userInfo: [NSLocalizedDescriptionKey:error.localizedDescription])
                    assembly.resp.set(error:err, index:idx)
                    DispatchQueue.main.async {
                        feedback.failed(index: idx, cmd: cmd, group: groupId, error: err)
                    } } }, catch: { (exception) in
                        isError = true
                        var msg = "not message"
                        if let tmsg = exception?.reason {
                            msg = tmsg
                        }
                        let err = NSError(domain: "RPC", code: -102, userInfo: [NSLocalizedDescriptionKey:msg])
                        assembly.resp.set(error:err, index:idx)
                        DispatchQueue.main.async {
                            feedback.failed(index: idx, cmd: cmd, group: groupId, error: err)
                        }
                }, finally: nil)
                
                if errbreak && isError {
                    break
                }
            }
            
            DispatchQueue.main.async { feedback.finish(group: groupId, assembly: assembly) }
        }
    }
    
    // workQueue
    private static let workQueue = DispatchQueue(label: "com.mm.rpc.queue", qos: DispatchQoS.background, attributes:.concurrent)
    
    //
//    private static let quantumQueue = DispatchQueue(label: "com.mm.rpc.quantum", qos: DispatchQoS.background)
//    private static let quantumCahce = RigidCache()
    
//    public init(_ quque:DispatchQueue, discrete: Bool = false, max size:Int = 6, interval:Int = 100) {
//        _queue = quque
//        _maxSize = size
//        _interval = interval
//    }
//
//    var _queue:DispatchQueue!
//    var _maxSize:Int = 6
//    var _interval:Int = 100 // (ms)
//    var _discrete = false
}

//
//  CltProfileViewController.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/24.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

class CltProfileViewController: MMUICollectionController<MMCellModel> {
    
    var profile:String = ""
    
    convenience init(_ str:String) {
        self.init(nibName: nil, bundle: nil)
    }
    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
//        fatalError("init(nibName:bundle:) has not been implemented")
//    }
    
    override func loadFetchs() -> [MMFetch<MMCellModel>] {
        //使用默认的数据库
        let list = [] as [MMCellModel]
        let f = MMFetchList(list:list)
        return [f]
    }
    
    override func onViewDidLoad() {
        super.onViewDidLoad()
        
        let profile = ssn_Arguments["profile"]?.string
        
        // Provisional request
        RPC.exec(task: { (idx, cmd, resp) -> Any in
            // do something
            return RPC.Result.empty
        }, feedback: self)

        // concurrent
        RPC.exec(cmds:[
            (CltProfileViewController.getFirstRemoteData,"getFirst"),
            (CltProfileViewController.getSecondRemoteData,"getSecond"),
            (CltProfileViewController.getLastRemoteData,"getLast")
            ],
                 feedback:self)
        
        // serial
        RPC.exec(cmds:[
            (CltProfileViewController.getFirstRemoteData,"getFirst"),
            (CltProfileViewController.getSecondRemoteData,"getSecond"),
            (CltProfileViewController.getLastRemoteData,"getLast")
            ],
                 queue:RPC.QueueModel.serial ,feedback:self)
    }
    
    
    class func getFirstRemoteData(_ index:RPC.Index, _ cmd:String?, _ resp:RPC.Response) throws -> Any {
        
        return "第一个任务请求数据"
    }
    
    class func getSecondRemoteData(_ index:RPC.Index, _ cmd:String?, _ resp:RPC.Response) throws -> Any {
        //取前一个数据
        let p = resp.getResult(RPC.Index(index.value-1), type: String.self)
        if p != nil {
            print("成功取到前面的数据:\"\(p!)\"")
        }
        return RPC.Result.empty
    }
    
    class func getLastRemoteData(_ index:RPC.Index, _ cmd:String?, _ resp:RPC.Response) throws -> Any {
        
        return RPC.Result.empty
    }
}

extension CltProfileViewController : Feedback {
    func start(group: String, assembly: RPC.AssemblyObject) {
//        assembly.setModel(fetchs[0])
    }
    
    func finish(group: String, assembly: RPC.AssemblyObject) {
        //
    }
    
    func failed(index: RPC.Index, cmd: String, group: String, error: NSError) {
        //
    }
    
    func staged(index: RPC.Index, cmd: String, group: String, result: Any, assembly: RPC.AssemblyObject) {
        switch index {
        case .first:
            let node = SettingNode()
            node.title = "数据0" + cmd + " " + group
            node.subTitle = "99"
            fetchs.fetch.append(node)
            break
        default:
            let node = SettingNode()
            node.title = "数据\(index.value)" + cmd + " " + group
            node.subTitle = "99"
            fetchs.fetch.insert(node, atIndex: index.value)
        }
    }
    
    
}

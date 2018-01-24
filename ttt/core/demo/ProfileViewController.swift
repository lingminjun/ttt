//
//  ProfileViewController.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/24.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

class ProfileViewController: MMUITableController<MMCellModel> {
    override func loadFetchs() -> [MMFetch<MMCellModel>] {
        //使用默认的数据库
        var list = [] as [MMCellModel]
        var f = MMFetchList(list:list)
        return [f]
    }
    
    override func onViewDidLoad() {
        super.onViewDidLoad()
        
        RPC.exec(task: { (idx, cmd, resp) -> Any in
            // do something
            return RPC.Result.empty
        }, feedback: self)

        RPC.exec(cmds:[
            (ProfileViewController.getFirstRemoteData,"getFirst"),
            (ProfileViewController.getSecondRemoteData,"getSecond"),
            (ProfileViewController.getLastRemoteData,"getLast")
            ],
                 feedback:self)
    }
    
    
    class func getFirstRemoteData(_ index:RPC.Index, _ cmd:String?, _ resp:RPC.Response) throws -> Any {
        
        return RPC.Result.empty
    }
    
    class func getSecondRemoteData(_ index:RPC.Index, _ cmd:String?, _ resp:RPC.Response) throws -> Any {
        
        return RPC.Result.empty
    }
    
    class func getLastRemoteData(_ index:RPC.Index, _ cmd:String?, _ resp:RPC.Response) throws -> Any {
        
        return RPC.Result.empty
    }
}

extension ProfileViewController : Feedback {
    func start(group: String, assembly: RPC.AssemblyObject) {
        //
    }
    
    func finish(group: String, assembly: RPC.AssemblyObject) {
        //
    }
    
    func failed(index: RPC.Index, cmd: String, group: String, error: NSError) {
        //
    }
    
    func staged(index: RPC.Index, cmd: String, group: String, result: Any, assembly: RPC.AssemblyObject) {
        //
    }
    
    
}

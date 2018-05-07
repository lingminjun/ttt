//
//  DetailViewController.swift
//  ttt
//
//  Created by lingminjun on 2018/5/3.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import RealmSwift

class DetailViewController: MMUITableController<MMCellModel>,FlyNotice {
    func on_data_update(dataId: String, model: FlyModel?, isDeleted: Bool) {
        if let dog = model as? Dog {
            self.dog = dog
            self.title = dog.breed + "(\(dog.brains))"
        }
    }
    
    
    var dog:Dog!
    
    //
    override func onViewDidLoad() {
        guard let breed = ssn_Arguments["breed"]?.string else {
            return
        }
        let realm = try! Realm()
        let vs = realm.objects(Dog.self).filter("breed='\(breed)'")
        if vs.count <= 0 {
            return
        }
        dog = vs[0]
        self.title = self.dog.breed + "(\(self.dog.brains))"
        
        let sel = #selector(ViewController.rightAction)
        //title: String?, style: UIBarButtonItemStyle, target: Any?, action: Selector?
        let item = UIBarButtonItem(title: "增加", style: UIBarButtonItemStyle.plain, target: self, action: sel)
        self.navigationItem.rightBarButtonItem=item
        
        DogManager.shared.fly.bind(breed, notice:self)
    }
    
    @objc func rightAction() -> Void {
       
        let realm = try! Realm()
        
        do {
            try realm.write {
                dog.brains = dog.brains + 1
//                realm.add(dog, update: true);//(newObjects)
                DogManager.shared.fly.save(dog)
            }
        } catch {
            print("error:\(error)")
        }
    }
}

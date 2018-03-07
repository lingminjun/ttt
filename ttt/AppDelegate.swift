//
//  AppDelegate.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/12.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import UIKit

@UIApplicationMain
public class AppDelegate: UIResponder, UIApplicationDelegate,Authorize {
    
    public var auth: Bool = false
    public func authorized() -> Bool {
        return auth
    }
    
    public func howToAuthorize(url: String, query: Dictionary<String, QValue>) -> String {
        return "https://m.mymm.com/user/login.html"
    }
    

    public var window: UIWindow?


    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame:UIScreen.main.bounds)
        Navigator.shared.launching(root: window!)
        Navigator.shared.addHost(host: "**mymm.com")
        Navigator.shared.addHost(host: "*.fengqu.com")
        Navigator.shared.addHost(host: "*.baidu.com")
        Navigator.shared.addScheme(scheme: "https")
        Navigator.shared.addScheme(scheme: "http")
        Navigator.shared.open("https://m.mymm.com")
        Navigator.shared.setAuthorize(auth: self)
        window?.makeKeyAndVisible()
        
//        //        (n,e)公钥 (3233, 17)
//        //        (n,d)私钥 (3233, 2753)
//        let n = BigInt8(truncatingIfNeeded:3233)
//        let e = BigInt8(truncatingIfNeeded:17)
//        let d = BigInt8(truncatingIfNeeded:2753)
//
//        let m = 65
//        let mc = BigInt8(truncatingIfNeeded:2790)
//
//        let c = BigInt8.pow(base:BigInt8(truncatingIfNeeded:m),exponent:e) % n  // 加密 m^e ≡ c (mod n)
//
//        if c == mc {
//            print("验证通过")
//        }
//
//        let a = BigInt8(truncatingIfNeeded:2)
//        let b = BigInt8(truncatingIfNeeded:3)
//
//        let x = BigInt8.pow(base: a, exponent: b)// a ^ b
//        if x == BigInt8(truncatingIfNeeded:8) {
//            print("验证通过")
//        }
        
//        if let bi = BInt.init("10000000", radix: 2) {
//            let b = bi.bytes
//            print("\(b)")
//
//            let xb = BInt.init(bytes: b)
//            print("\(xb)")
//
//            if bi == xb {
//                print("==========")
//            }
//        }
//
//        let bi = BInt.init(integerLiteral: -5)
//            let b = bi.bytes
//            print("\(b)")
//
//            let xb = BInt.init(bytes: b)
//            print("\(xb)")
//
//            if bi == xb {
//                print("==========")
//            }
//        }
//        rsa()
        
        
        return true
    }
    
    public static let PUB_KEY = "ZDY2YjcwZDY0ZjE3OGY3KzEwMDAx";
    
    //请妥善保存私钥，编译时请删除
    private static let PRI_KEY = "ZDY2YjcwZDY0ZjE3OGY3KzMyNDUyYzQ0OGFmNDM2MQ==";
    
    private func rsa() {
        let pub_key = "ZDY2YjcwZDY0ZjE3OGY3KzEwMDAx";
        let pri_key = "ZDY2YjcwZDY0ZjE3OGY3KzMyNDUyYzQ0OGFmNDM2MQ==";
        
        
        //            genRSA(800000000,1000000000);
        if true {
            let msg = "stackoverflow.com";
            let sign = "BmfRYZPsJKE=";
            print(sign);
            if let d = "stackoverflow.com".data(using: String.Encoding.utf8) {
                if (BriefRSA.verify(key:AppDelegate.PUB_KEY,sign:"BmfRYZPsJKE=",data:d)) {
                    print("verify true");
                }
            }
        }
        
        if true {
            let msg = "234455";
            if let msgD = msg.data(using: String.Encoding.utf8) {
                let sign = BriefRSA.sign(key:pri_key,data:msgD);
                print(sign);
                if (BriefRSA.verify(key:pub_key,sign:sign,data:msgD)) {
                    print("verify true");
                }
            }
        }
        
        if true {
            let msg = "www.fengqu.com";
            if let msgD = msg.data(using: String.Encoding.utf8) {
                let sign = BriefRSA.sign(key:pri_key,data:msgD);
                print(sign);
                if (BriefRSA.verify(key:pub_key,sign:sign,data:msgD)) {
                    print("verify true");
                }
            }
        }
        
        if true {
            let msg = "肖信波 杨世亮";
            if let msgD = msg.data(using: String.Encoding.utf8) {
                let sign = BriefRSA.sign(key:pri_key,data:msgD);
                print(sign);
                if (BriefRSA.verify(key:pub_key,sign:sign,data:msgD)) {
                    print("verify true");
                }
            }
        }
        
        if true {
            let msg = "打算大家送大礼斯柯达dhjkasakda哈佛爱的大声道啊";
            if let msgD = msg.data(using: String.Encoding.utf8) {
                let sign = BriefRSA.sign(key:pri_key,data:msgD);
                print(sign);
                if (BriefRSA.verify(key:pub_key,sign:sign,data:msgD)) {
                    print("verify true");
                }
            }
        }
        
        
    }

    public func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    public func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}


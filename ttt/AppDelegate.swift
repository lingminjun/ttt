//
//  AppDelegate.swift
//  ttt
//
//  Created by MJ Ling on 2018/1/12.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import UIKit


struct XStruct {
    var a:Int = 1
    var b:Int = 1
}

@UIApplicationMain
public class AppDelegate: UIResponder, UIApplicationDelegate,Authorize,MMTracker {
    public func pageEnter(page: MMTrackPage) {
        print("进入页面\(page.track_url())")
    }
    
    public func viewReveal(page: MMTrackPage, comp: MMTrackComponent) {
//        print("页面\(page)中元素\(comp)显示")
    }
    
    public func viewAction(page: MMTrackPage, comp: MMTrackComponent, event: UIEvent) {
        print("页面\(page)中元素\(comp)响应")
    }
    
    
    public var auth: Bool = false
    public func authorized() -> Bool {
        return auth
    }
    
    public func howToAuthorize(url: String, query: Dictionary<String, QValue>) -> String {
        return "https://m.mymm.com/user/login.html"
    }
    

    public var window: UIWindow?

    //test materializeForSet:
    var _ss:XStruct = XStruct()
    var ss:XStruct {
        get {
            var x:XStruct = _ss
            x.a = x.a + 1
            return x
        }
        set {
            _ss = newValue
        }
    }
    
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame:UIScreen.main.bounds)
        Navigator.shared.launching(root: window!)
        Navigator.shared.addHost(host: "**mymm.com")
        Navigator.shared.addHost(host: "*.fengqu.com")
//        Navigator.shared.addHost(host: "*.baidu.com")
        Navigator.shared.addScheme(scheme: "https")
        Navigator.shared.addScheme(scheme: "http")
        Navigator.shared.open("https://m.mymm.com")
        Navigator.shared.setAuthorize(auth: self)
        window?.makeKeyAndVisible()
        
        MMTrack.setTracker(tracker: self)
        
        self.ss.a = 2;
        self.ss.b = 3;
        
        print("\(self.ss.a),\(self.ss.b)")
    
        return true
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


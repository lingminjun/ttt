//
//  MMTrack.swift
//  ttt
//
//  Created by lingminjun on 2018/3/22.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation

//1:移动端iOS；2:移动端Android；3：移动端H5(微商城)；4:移动端微信小程序(预留)；5:移动端支付宝小程序(预留)
//6:PC浏览器(预留)；7:操作后台AC；8:操作后台MC；9:操作后台MNT
public let MYMM_APP_ID = 1

//定义主体 Page
@objc public protocol MMTrackPage {
    //属性
    func track_uri() -> String //页面位置
    func track_pid() -> String //pageId,应该与uri一一对应，5.1版本，对没有pageId的页面，不进行埋点
    func track_title() -> String //页面名称
    
    //事件
    func track_enter() -> Bool //进入事件，也是露出事件，返回true表示已处理，返回false，表示本身不处理
}

//定义主体 Component
@objc public protocol MMTrackComponent {
    //属性
    func track_vid() -> String //vid = [appId.]pageId.compId.compIdx.dataType.dataId.dataIndex
//    func track_vidPath() -> String //vid的相对值：compId.compIdx.dataType.dataId.dataIndex
    func track_name() -> String //组件上元素的具体名称，如登录、注册、提交、下单等等
    
    func track_mediaLink() -> String //事件所打的媒体数据
    
    
    //事件
    func track_reveal(depth:UInt) -> Void //露出事件
    func track_action() -> Void //响应事件  （播放，暂停事件均为响应事件，仅仅带媒体数据）
}

//定义事件：页面进入、元素露出、事件点击、视频自动播放(自动行为需要特别注意)
public protocol MMTracker {
    func pageEnter(page:MMTrackPage) //页面进入
    func viewReveal(page:MMTrackPage,comp:MMTrackComponent) //露出
    func viewAction(page:MMTrackPage,comp:MMTrackComponent) //响应
}

public final class MMTrack: MMTracker {
    private var _tracker:MMTracker?
    
    private init(tracker:MMTracker) {
        _tracker = tracker
    }
    
    public static func setTracker(tracker:MMTracker) {
        if THE_TRACKER != nil {
            return
        }
        THE_TRACKER = MMTrack(tracker:tracker)
    }
    
    public static func tracker() -> MMTracker {
        if THE_TRACKER == nil {
            fatalError("Please set tracker before used")
        }
        return THE_TRACKER!
    }
    
    public func pageEnter(page: MMTrackPage) {
        _tracker?.pageEnter(page: page)
    }
    
    public func viewReveal(page: MMTrackPage, comp: MMTrackComponent) {
        _tracker?.viewReveal(page: page, comp: comp)
    }
    
    public func viewAction(page: MMTrackPage, comp: MMTrackComponent) {
        _tracker?.viewAction(page: page, comp: comp)
    }
}

private var THE_TRACKER:MMTracker? = nil


// MARK:- automatic implementation
private var VIEW_CONSOLE_PROPERTY = 0
private var VIEW_URL_PROPERTY = 0
private var VIEW_PID_PROPERTY = 0
private var VIEW_VID_PATH_PROPERTY = 0
private var VIEW_VID_PROPERTY = 0
private var VIEW_MEDIA_PROPERTY = 0
public extension NSObject {
    //元素描述
    public var track_consoleTitle : String? {
        get{
            guard let result = objc_getAssociatedObject(self, &VIEW_CONSOLE_PROPERTY) as? String else {  return nil }
            return result
        }
        set {
            objc_setAssociatedObject(self, &VIEW_CONSOLE_PROPERTY, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    //页面url
    public var track_pageUri : String {
        get{
            guard let result = objc_getAssociatedObject(self, &VIEW_URL_PROPERTY) as? String else {  return "" }
            return result
        }
        set {
            objc_setAssociatedObject(self, &VIEW_URL_PROPERTY, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    //页面Id
    public var track_pageId : String {
        get{
            guard let result = objc_getAssociatedObject(self, &VIEW_PID_PROPERTY) as? String else {  return "" }
            return result
        }
        set {
            objc_setAssociatedObject(self, &VIEW_PID_PROPERTY, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    //visit path id :
    public var track_visitPathId : String {
        get{
            if let result = objc_getAssociatedObject(self, &VIEW_VID_PATH_PROPERTY) as? String {
                if !result.isEmpty {
                    return result
                }
            }
            
            //取visitId
            let vid = self.track_visitId
            if vid.isEmpty {
                return ""
            }
            
            //截取和面5位
            let ss = vid.split(separator: ".")
            if ss.count < 5 {
                return ""
            }
            
            return "\(ss[ss.count - 5]).\(ss[ss.count - 4]).\(ss[ss.count - 3]).\(ss[ss.count - 2]).\(ss[ss.count - 1])"
//            return String(ss[ss.count - 5]) + "." + String(ss[ss.count - 4]) + "." + String(ss[ss.count - 3]) + "." + String(ss[ss.count - 2]) + "." + String(ss[ss.count - 1])
        }
        set {
            //判断格式
            let ss = newValue.split(separator: ".")
            if ss.count != 5 {
                objc_setAssociatedObject(self, &VIEW_VID_PATH_PROPERTY, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            } else {
                objc_setAssociatedObject(self, &VIEW_VID_PATH_PROPERTY, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            }
        }
    }
    
    //visit id
    public var track_visitId : String {
        get{
            guard let result = objc_getAssociatedObject(self, &VIEW_VID_PROPERTY) as? String else {  return "" }
            return result
        }
        set {
            //判断格式 vid = [appId.]pageId.compId.compIdx.dataType.dataId.dataIndex
            let ss = newValue.split(separator: ".")
            if ss.count == 6 {
                objc_setAssociatedObject(self, &VIEW_VID_PROPERTY, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            } else if ss.count == 7 {//去除第一个appid，因为防止是其他品台带入的
                objc_setAssociatedObject(self, &VIEW_VID_PROPERTY, "\(ss[1]).\(ss[2]).\(ss[3]).\(ss[4]).\(ss[5]).\(ss[6])", objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            } else {
                objc_setAssociatedObject(self, &VIEW_VID_PROPERTY, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            }
        }
    }
    
    //media link
    public var track_media : String {
        get{
            guard let result = objc_getAssociatedObject(self, &VIEW_MEDIA_PROPERTY) as? String else {  return "" }
            return result
        }
        set {
            objc_setAssociatedObject(self, &VIEW_MEDIA_PROPERTY, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}

// MARK:- UIViewController: MMTrackPage
extension UIViewController:MMTrackPage {
    public func track_uri() -> String {
        return self.track_pageUri
    }
    
    public func track_pid() -> String {
        return self.track_pageId
    }
    
    public func track_title() -> String {
        if let t = self.track_consoleTitle, !t.isEmpty {
            return t
        }
        
        if let t = self.title, !t.isEmpty {
            return t
        }
        
        if let t = self.navigationItem.title, !t.isEmpty {
            return t
        }
        
        if let t = self.tabBarItem.title, !t.isEmpty {
            return t
        }
        
        return "\(type(of: self))"
    }
    
    // MARK:- Page页面进入
    public func track_enter() -> Bool {
        //默认只看vc
        let vcs = self.childViewControllers
        for vc in vcs {
            if (vc.track_enter()) {
                return true
            }
        }
        MMTrack.tracker().pageEnter(page: self)
        return true
    }
}

// MARK:- UIView: MMTrackComponent
extension UIView:MMTrackComponent {
    
    public final func track_uri() -> String {
        let uri = self.track_pageUri
        if !uri.isEmpty {
            return uri
        }
        
        if let vc = self.presentingPage() {
            let vcUri = vc.track_uri()
            if !vcUri.isEmpty {
                return vcUri
            }
        }
        
        return ""
    }
    
    public final func track_pid() -> String {
        let pid = self.track_pageId
        if !pid.isEmpty {
            return pid
        }
        
        if let vc = self.presentingPage() {
            let vcPid = vc.track_pid()
            if !vcPid.isEmpty {
                return vcPid
            }
        }
        
        return ""
    }
    
    public func track_vid() -> String {
        let vid = self.track_visitId
        if !vid.isEmpty {
            return vid
        }
        
        //自行组装
        let vpid = self.track_visitPathId
        if vpid.isEmpty {
            return ""
        }
        
        let pid = self.track_pid()
        if !vpid.isEmpty {
            return "\(pid).\(vpid)"
        }
        
        return ""
    }
    
    //不同的对象主要
    public func track_name() -> String {
        if let t = self.track_consoleTitle, !t.isEmpty {
            return t
        }
        return ""
    }
    
    public func track_mediaLink() -> String {
        return self.track_media
    }
    
    // MARK:- Component事件埋点
    public func track_reveal(depth:UInt) -> Void {
        //在window上
        guard let win = self.window /*UIApplication.shared.delegate?.window as? UIWindow*/ else { return } //[[[UIApplication sharedApplication] delegate] window];
        let rect = self.convert(self.bounds, to: win)//[self convertRect: view1.bounds toView:window];
        let inter = win.bounds.intersection(rect)
        //显示区域超过20%，
        if inter.size.width * inter.size.height < rect.size.width * rect.size.height * 0.2 {
            return
        }
        
        if depth > 0 {
            //默认行为如下
            let vs = self.subviews
            for v in vs {
                v.track_reveal(depth:depth - 1) //默认需要埋一篇
            }
        }
        
        //露出埋点
        if let page = self as? MMTrackPage {
            MMTrack.tracker().viewReveal(page: page, comp: self)
        } else if let vc = self.presentingPage() {
            MMTrack.tracker().viewReveal(page: vc, comp: self)
        }
    }
    
    public func track_action() {
        //响应埋点
        if let page = self as? MMTrackPage {
            MMTrack.tracker().viewAction(page: page, comp: self)
        } else if let vc = self.presentingPage() {
            MMTrack.tracker().viewAction(page: vc, comp: self)
        }
    }
    
    //默认行为是取自己的vc
    public final func presentingPage() -> UIViewController? {
        var responder = self.next
        while responder != nil {
            if let res = responder as? UIViewController {
                return res
            } else if responder is UIWindow {
                return nil
            }
            responder = responder?.next
        }
        return nil
    }
}

// MARK: - 针对UIKit中的元素进行默认值处理
extension UILabel {
    override public func track_name() -> String {
        let t = super.track_name()
        if !t.isEmpty {
            return t
        }
        if let str = self.text, !str.isEmpty {
            return str
        }
        return ""
    }
}

extension UIBarButtonItem:MMTrackComponent {
    public func track_name() -> String {
        if let t = self.track_consoleTitle, !t.isEmpty {
            return t
        }
        if let str = self.title, !str.isEmpty {
            return str
        }
        
//        public static var normal: UIControlState { get }
//        public static var highlighted: UIControlState { get } // used when UIControl isHighlighted is set
//        public static var disabled: UIControlState { get }
//        public static var selected: UIControlState { get } // flag usable by app (see below)
        
        if let str = self.possibleTitles?.first, !str.isEmpty {
            return str
        }
        if let v = self.customView {
            let str = v.track_name()
            if !str.isEmpty {
                return str
            }
        }
        return ""
    }
    
    //默认行为是取自己的vc
    public final func presentingPage() -> UIViewController? {
        if let vc = self.target as? UIViewController {
            return vc
        }
        if let vc = self.customView?.presentingPage() {
            return vc
        }
        return nil
    }
    
    public final func track_uri() -> String {
        let uri = self.track_pageUri
        if !uri.isEmpty {
            return uri
        }
        
        if let vc = self.presentingPage() {
            let vcUri = vc.track_uri()
            if !vcUri.isEmpty {
                return vcUri
            }
        }
        
        return ""
    }
    
    public final func track_pid() -> String {
        let pid = self.track_pageId
        if !pid.isEmpty {
            return pid
        }
        
        if let vc = self.presentingPage() {
            let vcPid = vc.track_pid()
            if !vcPid.isEmpty {
                return vcPid
            }
        }
        
        return ""
    }
    
    public func track_vid() -> String {
        let vid = self.track_visitId
        if !vid.isEmpty {
            return vid
        }
        
        //自行组装
        let vpid = self.track_visitPathId
        if vpid.isEmpty {
            return ""
        }
        
        let pid = self.track_pid()
        if !vpid.isEmpty {
            return "\(pid).\(vpid)"
        }
        
        return ""
    }
    
    public func track_mediaLink() -> String {
        return self.track_media
    }
    
    //MARK: 相关事件
    public func track_reveal(depth: UInt) {
        //忽略
    }
    
    public func track_action() {
        if let vc = self.presentingPage() {
            MMTrack.tracker().viewAction(page: vc, comp: self)
        }
    }
}

extension UIButton {
    override public func track_name() -> String {
        let t = super.track_name()
        if !t.isEmpty {
            return t
        }
        if let str = self.title(for: self.state), !str.isEmpty {
            return str
        }
        if let str = self.titleLabel?.text, !str.isEmpty {
            return str
        }
        return ""
    }
}

extension UISearchBar {
    override public func track_name() -> String {
        let t = super.track_name()
        if !t.isEmpty {
            return t
        }
        if let str = self.text, !str.isEmpty {
            return str
        }
        return ""
    }
}

extension UISegmentedControl {
    override public func track_name() -> String {
        let t = super.track_name()
        if !t.isEmpty {
            return t
        }
        if let str = self.titleForSegment(at: self.selectedSegmentIndex), !str.isEmpty {
            return str
        }
        return ""
    }
}

// MARK: - Reveal 事件重载
extension UITableView {
    override public func track_reveal(depth:UInt) -> Void {
        self.tableHeaderView?.track_reveal(depth: 0)
        self.tableFooterView?.track_reveal(depth: 0)
        
        //特殊处理，header或者footer
        for v in self.visibleCells {
            v.track_reveal(depth:depth) //默认需要埋一篇
        }
    }
    
    //滚动停止
    
}

extension UICollectionView {
    override public func track_reveal(depth:UInt) -> Void {
        //特殊处理
        for v in self.visibleCells {
            v.track_reveal(depth:depth) //默认需要埋一篇
        }
    }
    
    //滚动停止
}



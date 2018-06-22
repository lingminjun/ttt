//
//  MMTrack.swift
//  ttt
//
//  Created by lingminjun on 2018/3/22.
//  Copyright © 2018年 MJ Ling. All rights reserved.
//

import Foundation
import UIKit

//1:移动端iOS；2:移动端Android；3：移动端H5(微商城)；4:移动端微信小程序(预留)；5:移动端支付宝小程序(预留)；6:PC浏览器(预留)；7:操作后台AC；8:操作后台MC；9:操作后台MNT
public let MYMM_APP_ID = 1

public let REVEAL_DEPTH = 3

//定义主体 Page
@objc public protocol MMTrackPage {
    //属性
    func track_url() -> String //页面位置
    func track_pid() -> String //pageId,应该与uri一一对应，5.1版本，对没有pageId的页面，不进行埋点
    func track_title() -> String //页面名称
    
    //事件
    func track_enter() -> Void //进入事件，也是露出事件
}

//定义主体 Component
@objc public protocol MMTrackComponent {
    //属性
    func track_vid() -> String //vid = [appId.]pageId.compId.compIdx.dataType.dataId.dataIndex
//    func track_vidPath() -> String //vid的相对值：compId.compIdx.dataType.dataId.dataIndex
    func track_data_id() -> String   // 关联的业务数据id,与track_data_type()同时使用
    func track_data_type() -> String // 关联的业务数据类型,与track_data_id()同时使用
    func track_name() -> String //组件上元素的具体名称，如登录、注册、提交、下单等等
    
    func track_mediaLink() -> String //事件所打的媒体数据
    
    func track_page() -> MMTrackPage //所属页面
    
    
    //事件
    func track_reveal(depth:UInt) -> Void //露出事件
    func track_action(page:MMTrackPage?, event:UIEvent) -> Void //响应事件（播放，暂停事件均为响应事件，仅仅带媒体数据）
}

//定义事件：页面进入、元素露出、事件点击、视频自动播放(自动行为需要特别注意)
public protocol MMTracker {
    func pageEnter(page:MMTrackPage) //页面进入
    func viewReveal(page:MMTrackPage,comp:MMTrackComponent) //露出
    func viewAction(page:MMTrackPage,comp:MMTrackComponent,event:UIEvent) //响应
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
        
        //初始化一些需要跟踪的事件
        NSObject.swizzleMethod(target: UIViewController.self, #selector(UIViewController.viewDidAppear(_:)), #selector(UIViewController.track_viewDidAppear(_:)))
        NSObject.swizzleMethod(target: UIScrollView.self, NSSelectorFromString("_notifyDidScroll"), #selector(UIScrollView.track_notifyDidScroll))
        //NSObject.swizzleMethod(target: UIControl.self, #selector(UIControl.sendAction(_:to:for:)), #selector(UIControl.track_sendAction(_:to:for:)))
        NSObject.swizzleMethod(target: UIApplication.self, #selector(UIApplication.sendEvent(_:)), #selector(UIApplication.track_sendEvent(_:)))
        NSObject.swizzleMethod(target: UIApplication.self, #selector(UIApplication.sendAction(_:to:from:for:)), #selector(UIApplication.track_sendAction(_:to:from:for:)))
        
        //初始化
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
    
    public func viewAction(page: MMTrackPage, comp: MMTrackComponent,event:UIEvent) {
        _tracker?.viewAction(page: page, comp: comp, event:event)
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
private var VIEW_DATA_PROPERTY = 0

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
    public var track_pageUrl : String {
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
    
    //业务数据id和type
    public var track_data_id : String {
        get{
            return NSObject.track_parse_data_id(data:self.track_data)
        }
    }
    public var track_data_type : String {
        get{
            return NSObject.track_parse_data_type(data:self.track_data)
        }
    }
    
    public func track_data(id:String, type:String) {
        if id.isEmpty && type.isEmpty {
            objc_setAssociatedObject(self, &VIEW_DATA_PROPERTY, nil, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
            return
        }
        let newValue = "\(type).\(id)"
        objc_setAssociatedObject(self, &VIEW_DATA_PROPERTY, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    fileprivate var track_data : String {
        get{
            if let result = objc_getAssociatedObject(self, &VIEW_DATA_PROPERTY) as? String,!result.isEmpty {  return result }
            //从vid中取值
            let vid = self.track_visitId //pageId.compId.compIdx.dataType.dataId.dataIndex
            let ss = vid.split(separator: ".")
            if ss.count != 6 {
                return ""
            }
            return "\(ss[3]).\(ss[4])"
        }
    }
    fileprivate static func track_parse_data_id(data:String) -> String {
        guard let range = data.range(of: ".") else { return "" }
        return "\(data[range.upperBound..<data.endIndex])"
    }
    fileprivate static func track_parse_data_type(data:String) -> String {
        guard let idx = data.index(of: ".") else { return "" }
        return "\(data[data.startIndex..<idx])"
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
    
    //方法替换
    fileprivate static func swizzleMethod(target: NSObject.Type, _ left: Selector, _ right: Selector) {
        
        guard let originalMethod = class_getInstanceMethod(target, left), let swizzledMethod = class_getInstanceMethod(target, right) else {
            return
        }
        
        let didAddMethod = class_addMethod(target, left, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        
        if didAddMethod {
            class_replaceMethod(target, right, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    }
}

// MARK:- UIViewController: MMTrackPage
extension UIViewController: MMTrackPage {
    public func track_url() -> String {
        let uri = self.track_pageUrl
        
        if !uri.isEmpty {
            return uri
        }
        
        //支持navigator自带uri的概念
        return self._node.url
    }
    
    public func track_pid() -> String {
        let id = self.track_pageId
        
        if !id.isEmpty {
            return id
        }
        
        if !_node.params.isEmpty {
            if let v = self.ssn_Arguments[_node.params[0]]?.string {
                return v
            }
        }
        
        return ""
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
    public func track_enter() -> Void {
        MMTrack.tracker().pageEnter(page: self)
    }
    
    @objc public func track_topPage() -> UIViewController {
        return self
    }
}

extension UINavigationController {
    @objc public override func track_topPage() -> UIViewController {
        if let vc = self.topViewController {
            return vc.track_topPage()
        }
        return super.track_topPage()
    }
}

extension UITabBarController {
    @objc public override func track_topPage() -> UIViewController {
        if let vc = self.selectedViewController {
            return vc.track_topPage()
        }
        return super.track_topPage()
    }
}

extension UIPageViewController {
    @objc public override func track_topPage() -> UIViewController {
        guard let vs = self.viewControllers else {
            return super.track_topPage()
        }
        guard let win = self.view.window else {
            return super.track_topPage()
        }
        for v in vs {
            let wc = v.view.convert(v.view.center, to:win)
            //使用y值判断
            if wc.y == win.center.y {
                return v.track_topPage()
            }
        }
        return super.track_topPage()
    }
}

// MARK:- UIView: MMTrackComponent
let TRACK_FIND_ELEMENT_FLAG_DEEP:UInt = 3

extension UIView:MMTrackComponent {
    
    public func track_data_id() -> String {
        return NSObject.track_parse_data_id(data:self.track_data(superView:true))
    }
    
    public func track_data_type() -> String {
        return NSObject.track_parse_data_type(data:self.track_data(superView:true))
    }
    
    @objc func track_data(superView:Bool) -> String {
        let vid = self.track_data
        if !vid.isEmpty {
            return vid
        }
        
        // 支持一些特殊按钮，系统UIBarButtonItem中的几种，返回
        if !superView {
            return ""
        }
        
        //往上找3层
        return UIView.track_super_data(view: self, depth: TRACK_FIND_ELEMENT_FLAG_DEEP)
    }
    
    private static func track_super_data(view:UIView, depth:UInt) -> String {
        if depth == 0 {
            return ""
        }
        
        //先取
        guard let svs = view.superview else { return "" }
        let str = svs.track_data(superView: false)
        if !str.isEmpty {
            return str
        }
        
        //再递归
        if depth > 1 {
            let str = UIView.track_super_data(view: svs, depth: depth - 1)
            if !str.isEmpty {
                return str
            }
        }
        return ""
    }

    
    public func track_page() -> MMTrackPage {
        if let page = self as? MMTrackPage {
            return page
        } else if let vc = self.presentingPage()?.track_topPage() {
            return vc
        }
        return UIViewController()
    }
    
    
    public final func track_uri() -> String {
        let uri = self.track_pageUrl
        if !uri.isEmpty {
            return uri
        }
        
        if let vc = self.presentingPage() {
            let vcUri = vc.track_url()
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
        return track_vid(superView:true)
    }
    
    @objc func track_vid(superView:Bool) -> String {
        let vid = self.track_visitId
        if !vid.isEmpty {
            return vid
        }
        
        //自行组装
        let vpid = self.track_visitPathId
        if !vpid.isEmpty {
            let pid = self.track_pid()
            if !pid.isEmpty {
                return "\(pid).\(vpid)"
            }
        }
        
        // 支持一些特殊按钮，系统UIBarButtonItem中的几种，返回
        if !superView {
            return ""
        }
        
        //往上找3层
        return UIView.track_super_vid(view: self, depth: TRACK_FIND_ELEMENT_FLAG_DEEP)
    }
    
    private static func track_super_vid(view:UIView, depth:UInt) -> String {
        if depth == 0 {
            return ""
        }
        
        //先取
        guard let svs = view.superview else { return "" }
        let str = svs.track_vid(superView: false)
        if !str.isEmpty {
            return str
        }
        
        //再递归
        if depth > 1 {
            let str = UIView.track_super_vid(view: svs, depth: depth - 1)
            if !str.isEmpty {
                return str
            }
        }
        return ""
    }
    
    //不同的对象主要
    public func track_name() -> String {
        return track_name(child: true)
    }
    
    @objc func track_name(child:Bool) -> String {
        if let t = self.track_consoleTitle, !t.isEmpty {
            return t
        }
        
        // 支持一些特殊按钮，系统UIBarButtonItem中的几种，返回
        if !child {
            return ""
        }
        
        return UIView.track_children_name(view: self, depth: TRACK_FIND_ELEMENT_FLAG_DEEP)
    }
    
    private static func track_children_name(view:UIView, depth:UInt) -> String {
        if depth == 0 {
            return ""
        }
        
        //先取
        let svs = view.subviews
        for v in svs {
            let str = v.track_name(child: false)
            if !str.isEmpty {
                return str
            }
        }
        
        //再递归
        if depth > 1 {
            for v in svs {
                let str = UIView.track_children_name(view: v, depth: depth - 1)
                if !str.isEmpty {
                    return str
                }
            }
        }
        return ""
    }
    
    public func track_mediaLink() -> String {
        return self.track_media
    }
    
    // MARK:- Component事件埋点
    public func track_reveal(depth:UInt) -> Void {
        track_reveal(depth: depth, notscroll:false)
    }
    fileprivate final func track_reveal(depth:UInt, notscroll:Bool) -> Void {
        
        if notscroll && self is UIScrollView {
            return
        }
        
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
                if notscroll && v is UIScrollView {
                    continue
                } else {
                    v.track_reveal(depth:depth - 1) //默认需要埋一篇
                }
            }
        }
        
        //露出埋点
        if let page = self as? MMTrackPage {
            MMTrack.tracker().viewReveal(page: page, comp: self)
        } else if let vc = self.presentingPage()?.track_topPage() {
            MMTrack.tracker().viewReveal(page: vc, comp: self)
        }
    }
    
    public func track_action(page: MMTrackPage?, event: UIEvent) {
        //响应埋点
        if let page = page {
            MMTrack.tracker().viewAction(page: page, comp: self, event: event)
        } else if let page = self as? MMTrackPage {
            MMTrack.tracker().viewAction(page: page, comp: self, event: event)
        } else if let vc = self.presentingPage()?.track_topPage() {
            MMTrack.tracker().viewAction(page: vc, comp: self, event: event)
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
    @objc override func track_name(child:Bool) -> String {
        let t = super.track_name(child:child)
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
    public func track_data_id() -> String {
        return NSObject.track_parse_data_id(data:track_data)
    }
    
    public func track_data_type() -> String {
        return NSObject.track_parse_data_id(data:track_data)
    }
    
    
    public func track_page() -> MMTrackPage {
        if let vc = self.presentingPage()?.track_topPage() {
            return vc
        }
        return UIViewController()
    }
    
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
        let uri = self.track_pageUrl
        if !uri.isEmpty {
            return uri
        }
        
        if let vc = self.presentingPage() {
            let vcUri = vc.track_url()
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
        if !pid.isEmpty {
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
    
    public func track_action(page: MMTrackPage?, event: UIEvent) {
        if let page = page {
            MMTrack.tracker().viewAction(page: page, comp: self, event: event)
        } else if let vc = self.presentingPage()?.track_topPage() {
            MMTrack.tracker().viewAction(page: vc, comp: self, event: event)
        }
    }
}

extension UIButton {
     @objc override func track_name(child:Bool) -> String {
        if let t = self.track_consoleTitle, !t.isEmpty {
            return t
        }
        
        var state = self.state
        if self.isSelected {
            state = .selected
        }
        
        if let str = self.image(for: state)?.track_consoleTitle, !str.isEmpty {
            return str
        }
        
        if let str = self.title(for: state), !str.isEmpty {
            return str
        }
        
        if let str = self.titleLabel?.text, !str.isEmpty {
            return str
        }
        
        let t = super.track_name(child:child)
        if !t.isEmpty {
            return t
        }
        
        return ""
    }
}

extension UISearchBar {
     @objc override func track_name(child:Bool) -> String {
        let t = super.track_name(child:child)
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
     @objc override func track_name(child:Bool) -> String {
        let t = super.track_name(child:child)
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
extension UIScrollView {
    //notice
    @objc public func track_notifyDidScroll() -> Void {
        // …then immediately cancel it
        let sel = #selector(UIScrollView.didEndScrollingAnimation)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: sel, object: nil)
        
        self.track_notifyDidScroll()
        
        perform(sel, with: nil, afterDelay: 0.1)
    }
    
    @objc public func didEndScrollingAnimation() {
        self.track_reveal(depth: 2)
    }
}

extension UITableView {
    override public func track_reveal(depth:UInt) -> Void {
        self.tableHeaderView?.track_reveal(depth: 0)
        self.tableFooterView?.track_reveal(depth: 0)
        
        //特殊处理，header或者footer
        for v in self.visibleCells {
            v.track_reveal(depth:depth) //默认需要埋一篇
        }
    }
}

extension UICollectionView {
    override public func track_reveal(depth:UInt) -> Void {
        //特殊处理
        for v in self.visibleCells {
            v.track_reveal(depth:depth) //默认需要埋一篇
        }
    }
}


// MARK: - 针对UIKit中页面展现时机选取
extension UIViewController {
    @objc func track_viewDidAppear(_ animated: Bool) {
        self.track_viewDidAppear(animated)
        
        //页面进入事件
        self.track_enter()
        
        //非顶层view，不做埋点
        if self is UINavigationController
            || self is UITabBarController
            || self is UIPageViewController {
            return
        }
        
        //scrollview本身会在didEndScrollingAnimation时上报，所以此处请过滤
        if let v = self.view {
            v.track_reveal(depth: 3, notscroll:true)
        }
    }
}

// MARK: - 针对UIKit中响应事件时机选取
/* all the event will be dispatched UIApplication
extension UIControl {
    @objc func track_sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        self.track_sendAction(action, to: target, for: event)
        
        if let event = event,let comp = target as? MMTrackComponent {
            comp.track_action(event:event)
        }
    }
}*/


private var dispatchEvent = 0 //表示处理过
extension UIApplication {
    
    @objc func track_sendEvent(_ event: UIEvent) {
        dispatchEvent = dispatchEvent + 1
        
        var page:MMTrackPage? = nil
        var comp:MMTrackComponent? = nil
        
        if event.type != .motion && event.type != .remoteControl {
            if let ts = event.allTouches,ts.count > 0 {
                for tc in ts {
                    if tc.phase == .ended {
                        if let c = tc.view {
                            if #available(iOS 9.0, *) {
                                if tc.type != .indirect {
                                    comp = c
                                    break
                                }
                            } else {
                                comp = c
                                break
                            }
                        }
                    }
                }
                
                if let comp = comp {
                    page = comp.track_page()//必须提前取页面，方式事件是跳出页面
                }
            }
        }

        self.track_sendEvent(event)
        
        if dispatchEvent == 1 {
            if let comp = comp {
                comp.track_action(page:page, event:event)
            }
        }
        
        dispatchEvent = dispatchEvent - 1
        if dispatchEvent < 0 {
            dispatchEvent = 0
        }
    }
    
    @objc func track_sendAction(_ action: Selector, to target: Any?, from sender: Any?, for event: UIEvent?) -> Bool {
        
        var page:MMTrackPage? = nil
        var comp:MMTrackComponent? = nil
        
        if let c = sender as? MMTrackComponent {
            page = c.track_page() //必须提前取页面，方式事件是跳出页面
            comp = c
        }
        
        let rt = self.track_sendAction(action, to: target, from: sender, for: event)
        
        if rt && dispatchEvent > 0 {
            var compName = ""
            if "\(action)" == "__backButtonAction:" {
                compName = "返回"
            }
            if let event = event,let comp = comp {
                if !compName.isEmpty {
                    if let obj = comp as? NSObject {
                        obj.track_consoleTitle = compName
                    }
                }
                comp.track_action(page:page, event:event)
                dispatchEvent = dispatchEvent - 1
            }
        }
        
        
        return rt
    }
}

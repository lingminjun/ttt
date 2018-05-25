//
//  MMFetchsController.swift
//  merchant-ios
//
//  Created by MJ Ling on 2018/1/5.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation
import UIKit

/// Cell model is data obj
@objc public protocol MMCellModel : NSObjectProtocol {
    func ssn_cellID() -> String
    func ssn_groupID() -> String? //分组实现
    @objc optional func ssn_cell(_ cellID : String) -> UITableViewCell //适应于UITableView，尽量不采用反射方式
    func ssn_canEdit() -> Bool
    func ssn_canMove() -> Bool
    func ssn_cellHeight() -> CGFloat //UITableViewDelegate heightForRowAt or UICollectionViewLayout layoutAttributesForItemAtIndexPath
    func ssn_cellInsets() -> UIEdgeInsets //内边距，floating将忽略此致
    func ssn_canFloating() -> Bool
    func ssn_isExclusiveLine() -> Bool
    func ssn_cellGridSpanSize() -> Int //占用列数，小于等于零表示1
    
    @objc optional func ssn_cellClass(_ cellID : String, isFloating:Bool) -> Swift.AnyClass //返回cell class类型
    @objc optional func ssn_cellNib(_ cellID : String, isFloating:Bool) -> UINib //返回cell class类型
    
}

private var CELL_MODEL_PROPERTY = 0
private var CELL_FETCHS_PROPERTY = 0

/// UITableViewCell display support or UICollectionReusableView display support
extension UIView {
    
    @objc var ssn_cellModel : MMCellModel? {
        get{
            guard let result = objc_getAssociatedObject(self, &CELL_MODEL_PROPERTY) as? MMCellModel else {  return nil }
            return result
        }
//        set{
//            objc_setAssociatedObject(self, &CELL_MODEL_PROPERTY, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN))
//        }
    }
    
    /*
        func prepareForReuse()
        @Params tableView Presenting table
        @Params model     Rendering by data
        @Params atIndexPath
        @Params reused    It is reuse scenario. The previous model(old model) is equal to the current model.
                          This value depends on the isEquale method you implement.
                          Value is true that maybe means updating the model
    */
    @objc func ssn_onDisplay(_ tableView: UIScrollView, model: AnyObject,atIndexPath indexPath: IndexPath, reused: Bool) {}
    
    fileprivate func ssn_set_cellModel(_ model:MMCellModel?) {
        objc_setAssociatedObject(self, &CELL_MODEL_PROPERTY, model, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    
    // fetchs. be careful fetchs is MMFetchsController
    var ssn_fetchs : AnyObject? {
        get{
            guard let result = objc_getAssociatedObject(self, &CELL_FETCHS_PROPERTY) else {  return nil }
            return result as AnyObject
        }
    }
    
    fileprivate func ssn_weak_set_fetchs(_ fetchs:AnyObject?) {
        objc_setAssociatedObject(self, &CELL_FETCHS_PROPERTY, fetchs, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
    }
}

/// UICollectionReusableView display support
//extension UICollectionReusableView {
//    @objc var ssn_cellModel : MMCellModel? {
//        get{
//            guard let result = objc_getAssociatedObject(self, &CELL_MODEL_PROPERTY) as? MMCellModel else {  return nil }
//            return result
//        }
//    }
//
//    //    func prepareForReuse()
//    @objc func ssn_onDisplay(_ tableView: UICollectionView, model: AnyObject,atIndexPath indexPath: IndexPath) {}
//
//    fileprivate func ssn_set_cellModel(_ model:MMCellModel?) {
//        objc_setAssociatedObject(self, &CELL_MODEL_PROPERTY, model, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
//    }
//}

///
@objc public enum MMFetchChangeType : UInt {
    case insert
    case delete
    case move
    case update
}

///
//public protocol MMFetchChangedListener {
//    func ssn_fetch_begin_change(_ fetch: MMFetch<<#T: MMCellModel#>>)
//    func ssn_fetch_end_change(_ fetch: MMFetch<<#T: MMCellModel#>>)
//    func ssn_fetch(_ fetch: MMFetch<MMCellModel>, didChange anObject: MMCellModel, at index: Int, for type: MMFetchChangeType, newIndex: Int)
//}

/// All fetch list abstract protocol
public class MMFetch<T: MMCellModel> {
    let _tag: String
    weak var _listener : MMFetchsController<T>?
    
    public init(tag: String) {
        _tag = tag
    }
    
    /// The tag is FetchList id
    public final var tag: String { get{return _tag }}
    public final var title: String?
    public final var footer: String?
    
    /// Access the `index`th element. Reading is O(1).  Writing is
    /// O(1) unless `self`'s storage is shared with another live array; O(`count`) if `self` does not wrap a bridged `NSArray`; otherwise the efficiency is unspecified..
    public final subscript (index: Int) -> T? { get{ return self.get(index)} set(newValue) {
        if let newValue = newValue {
            self.insert(newValue, atIndex: index)}
        }
    }
    
    /// Gets the first element in the array.
    public final func first() -> T? { if self.count() > 0 { return get(0) } else { return nil }}
    /// Gets the last element from the array.
    public final func last() -> T? {if self.count() > 0 { return get(self.count() - 1) } else { return nil }}
    
    public final func insert(_ newObject: T, atIndex i: Int) {
        self.insert([newObject], atIndex: i)
    }
    
    /// Remove an element from the end of the Array in O(1). Derived class implements.
    public final func removeLast() -> T? {
        if self.count() > 0 {
            return self.delete(self.count() - 1)
        }
        return nil
    }
    
    /// Get element for predicate. Derived class implements.
    public final func get(_ predicate: NSPredicate) -> T? {
        let models = filter(predicate)
        if models.count == 1 {
            return models[0]
        }
        return nil
    }
    
    /// Get element for predicate.
    public final func get(_ predicateFormat: String, _ args: AnyObject...) -> T? {
        return self.get(NSPredicate(format: predicateFormat, argumentArray: args))
    }
    
    /// Returns the index of the first object matching the predicate. Derived class implements.
    public final func indexOf(_ predicate: NSPredicate) -> Int? {
        if let model = self.get(predicate) {
            return indexOf(model)
        }
        return nil
    }
    
    /// Returns the index of the first object matching the predicate.
    public final func indexOf(_ predicateFormat: String, _ args: AnyObject...) -> Int? {
        return self.indexOf(NSPredicate(format: predicateFormat, argumentArray: args))
    }
    
    
    // MARK: Filtering
    /// Returns all objects matching the given predicate in the collection.
    public final func filter(_ predicateFormat: String, _ args: AnyObject...) -> [T] {
        return self.filter(NSPredicate(format: predicateFormat, argumentArray: args))
    }

    /// Append object.
    public final func append(_ newObject: T) {
        self.insert(newObject, atIndex: self.count())
    }
    public final func append<C: Sequence>(_ newObjects: C) where C.Iterator.Element == T {
        for obj in newObjects {
            self.append(obj)
        }
    }
    
    // MARK: These require a subclass implementation
    
    /// Derived class implements
    public func count() -> Int {return 0}
    public func objects/*<S: SequenceType where S.Generator.Element: Object>*/() -> [T]? { return nil}
    
    /// Update
    public func update(_ idx: Int, _ b: (() throws -> Void)?) {}
    /// Insert `newObject` at index `i`. Derived class implements.
    public func insert<C: Sequence>(_ newObjects: C, atIndex i: Int) where C.Iterator.Element == T {
        /*_listener?.ssn_fetch(fetch: self,didChange: newObject, at: self.count(), for: MMFetchChangeType.insert, newIndex: self.count())*/
    }
    
    /// Remove and return the element at index `i`. Derived class implements.
    public func delete(_ index: Int) -> T? {return nil}
    public func delete(_ index: Int, length: Int) {}
    
    
    /// Remove all elements. Derived class implements.
    public func clear() {}
    
    /// Get element at index. Derived class implements.
    public func get(_ index: Int) -> T? {return nil}
    
    /// Returns the index of an object in the results collection. Derived class implements.
    public func indexOf(_ object: T) -> Int? {return 0}
    public func filter(_ predicate: NSPredicate) -> [T] {return []}
    
    // support group
    public func range(group:String,reversed:Bool = false) -> Range<Int>? {
        var begin = 0
        var end = 0
        var find = false
        if reversed {
            for i in (0..<self.count()).reversed() {
                if let m = self.get(i), let g = m.ssn_groupID(), g == group {
                    if !find {
                        end = i + 1
                    }
                    begin = i //往前移
                    find = true
                } else if find {
                    break
                }
            }
        } else {
            for i in 0..<self.count() {
                if let m = self.get(i), let g = m.ssn_groupID(), g == group {
                    if !find {
                        begin = i
                    }
                    end = i + 1 //往后移
                    find = true
                } else if find {
                    break
                }
            }
        }
        
        if !find {
            return nil
        }
        
        return begin..<end
    }
}

/*
enum MMTable {
    case tableView(UITableView)
    case collectionView(UICollectionView)
}
*/

/// Listening the fetch controller changes
@objc public protocol MMFetchsControllerDelegate : NSObjectProtocol {
    
    //参照写法
    //        _notice?.stop()
    //        _notice = _list?.addNotificationBlock { [weak self] (changes: RealmCollectionChange) in
    //            guard let tableView = self?.tableView else { return }
    //            switch changes {
    //            case .initial:
    //                tableView.reloadData()
    //                break
    //            case .update(_, let deletions, let insertions, let modifications):
    //                tableView.beginUpdates()
    //
    //                tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
    //
    //                tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
    //                tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
    //                tableView.endUpdates()
    //                break
    //            case .error(let error):
    //                print("Error: \(error)")
    //                break
    //            }
    //        }
    
    
    /* Notifies the delegate that a fetched object has been changed due to an add, remove, move, or update. Enables NSFetchedResultsController change tracking.
    	controller - controller instance that noticed the change on its fetched objects
    	anObject - changed object
    	indexPath - indexPath of changed object (nil for inserts)
    	type - indicates if the change was an insert, delete, move, or update
    	newIndexPath - the destination path of changed object (nil for deletes)
    	
    	Changes are reported with the following heuristics:
     
    	Inserts and Deletes are reported when an object is created, destroyed, or changed in such a way that changes whether it matches the fetch request's predicate. Only the Inserted/Deleted object is reported; like inserting/deleting from an array, it's assumed that all objects that come after the affected object shift appropriately.
    	Move is reported when an object changes in a manner that affects its position in the results.  An update of the object is assumed in this case, no separate update message is sent to the delegate.
    	Update is reported when an object's state changes, and the changes do not affect the object's position in the results.
     */
    
    @objc optional func ssn_controller(_ controller: AnyObject, didChange anObject: MMCellModel?, at indexPath: IndexPath?, for type: MMFetchChangeType, newIndexPath: IndexPath?)
    
    
    /* Notifies the delegate of added or removed sections.  Enables NSFetchedResultsController change tracking.
     
    	controller - controller instance that noticed the change on its sections
    	sectionInfo - changed section
    	index - index of changed section
    	type - indicates if the change was an insert or delete
     
    	Changes on section info are reported before changes on fetchedObjects.
     */
    //@objc optional func ssn_controller(_ controller: AnyObject, didChange sectionInfo: AnyObject, atSectionIndex sectionIndex: Int, for type: MMFetchChangeType)
    
    
    /* Notifies the delegate that section and object changes are about to be processed and notifications will be sent.  Enables NSFetchedResultsController change tracking.
     Clients may prepare for a batch of updates by using this method to begin an update block for their view.
     */
    func ssn_controllerWillChangeContent(_ controller: AnyObject)
    
    
    /* Notifies the delegate that all section and object changes have been sent. Enables NSFetchedResultsController change tracking.
     Clients may prepare for a batch of updates by using this method to begin an update block for their view.
     Providing an empty implementation will enable change tracking if you do not care about the individual callbacks.
     */
    func ssn_controllerDidChangeContent(_ controller: AnyObject)
    
    
    /* Asks the delegate to return the corresponding section index entry for a given section name.	Does not enable NSFetchedResultsController change tracking.
     If this method isn't implemented by the delegate, the default implementation returns the capitalized first letter of the section name (seee NSFetchedResultsController fetchTitleForSectionName:)
     Only needed if a section index is used.
     */
    @objc optional func ssn_controller(_ controller: AnyObject, fetchTitleForFetchTag tag: String) -> String?
    
    
    // Data manipulation - insert and delete support
    @objc optional func ssn_controller(_ controller: AnyObject, tableView: UIScrollView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) -> Bool
    
    // Data manipulation - reorder / moving support
    @objc optional func ssn_controller(_ controller: AnyObject, tableView: UIScrollView, moveRowAtIndexPath sourceIndexPath: IndexPath, toIndexPath destinationIndexPath: IndexPath)
}

let DEFAULT_CELL_ID = ".default.cell"
let DEFAULT_HEAD_ID = ".default.head"

/**
 * MMFetchsController实现UITableViewDataSource
 */
public class MMFetchsController<T: MMCellModel> : NSObject,UITableViewDataSource,UICollectionViewDataSource /*,UITableViewDelegate*/ {
    
    var _fetchs = [] as [MMFetch<T>]
    var _isRgst:Set<String> = Set<String>()
    
    
    weak var _delegate : MMFetchsControllerDelegate?
    
    /// 设置delegate
    public var delegate : MMFetchsControllerDelegate? {
        set {
//            if delegate != nil {
//            }
            _delegate = newValue
        }
        get {
            return _delegate
        }
    }
    
    /* ========================================================*/
    /* ========================= INITIALIZERS ====================*/
    /* ========================================================*/
    
    /* Initializes an instance of NSFetchedResultsController
    	fetchRequest - the fetch request used to get the objects. It's expected that the sort descriptor used in the request groups the objects into sections.
    	context - the context that will hold the fetched objects
    	sectionNameKeyPath - keypath on resulting objects that returns the section name. This will be used to pre-compute the section information.
    	cacheName - Section info is cached persistently to a private file under this name. Cached sections are checked to see if the time stamp matches the store, but not if you have illegally mutated the readonly fetch request, predicate, or sort descriptor.
     */
    public convenience init(fetch: MMFetch<T>) {
        self.init(fetchs: [fetch])
    }
    
    public init(fetchs: [MMFetch<T>]) {
        super.init()
        _fetchs = fetchs
        if _fetchs.isEmpty {
            _fetchs.append(MMFetchList(tag:"default"))
        }
        for fetch in fetchs {
            fetch._listener = self
        }
    }
    
//    deinit {
//        print("释放fetchs")
//    }
    
    /// The number of Fetchs in the controller.
    public func count() -> Int {
        return _fetchs.count
    }
    
    /// get the first fetch. It is convenience to use
    public var fetch:MMFetch<T> {
        get {
            return self[0]!
        }
    }
    
    /**
     Returns the MMFetch at the given `index`.
     
     - parameter index: An index.
     
     - returns: The MMFetch at the given `index`.
     */
    public subscript(index: Int) -> MMFetch<T>? {
        get {
            if index < 0 && index >= _fetchs.count { return nil}
            return _fetchs[index];
        }
    }
    
    /* Executes the fetch request on the store to get objects.
     Returns YES if successful or NO (and an error) if a problem occurred.
     An error is returned if the fetch request specified doesn't include a sort descriptor that uses sectionNameKeyPath.
     After executing this method, the fetched objects can be accessed with the property 'fetchedObjects'
     */
    public func performFetch() throws {
        
    }
    
    
    /* Returns the fetched object at a given indexPath.
     */
    public func object(at indexPath: IndexPath) -> T? {
        return (self[indexPath.section]?[indexPath.row]);
    }
    
    /* update indexPath.
     */
    public func update(at indexPath: IndexPath,_ b: (() throws -> Void)?) {
        self[indexPath.section]?.update(indexPath.row, b)
    }
    
    /* delete indexPath.
     */
    public func delete(at indexPath: IndexPath) {
        _ = self[indexPath.section]?.delete(indexPath.row)
    }
    
    /* insert indexPath.
     */
    public func insert(obj:T, at indexPath: IndexPath) {
        self[indexPath.section]?.insert(obj, atIndex: indexPath.row)
    }
    
    
    /* Returns the indexPath of a given object.
     */
    public func indexPath(forObject object: T) -> IndexPath? {
        for section in 0..<_fetchs.count {
            let fetch = self[section]
            if let row = fetch?.indexOf(object) {
//                return IndexPath(indexes: [section,row], length: 2)
                return IndexPath(row: row, section: section)
            }
        }
        return nil
    }
    
    
    /* ========================================================*/
    /* =========== CONFIGURING SECTION INFORMATION ============*/
    /* ========================================================*/
    /*	These are meant to be optionally overridden by developers.
     */
    
    /* Returns the corresponding section index entry for a given section name.
     Default implementation returns the capitalized first letter of the section name.
     Developers that need different behavior can implement the delegate method -(NSString*)controller:(NSFetchedResultsController *)controller fetchTitleForSectionName
     Only needed if a section index is used.
     */
    public func fetch(forFetchTag fetchTag: String) -> MMFetch<T>? {
        for fetch in _fetchs {
            if fetch.tag == fetchTag {
                return fetch
            }
        }
        return nil

    }
    
    /* Returns the corresponding section index entry for a given section name.
     Default implementation returns the capitalized first letter of the section name.
     Developers that need different behavior can implement the delegate method -(NSString*)controller:(NSFetchedResultsController *)controller fetchTitleForSectionName
     Only needed if a section index is used.
     */
    public func fetchTitle(forFetchTag fetchTag: String) -> String? {
        for fetch in _fetchs {
            if fetch.tag == fetchTag {
                return fetch.title
            }
        }
        return nil
    }
    
    public func fetchIndex(forFetchTag fetchTag: String) -> Int? {
        for index in 0..<_fetchs.count {
            if _fetchs[index].tag == fetchTag {
                return index
            }
        }
        return nil
    }
    
    func indexOf(_ fetch: MMFetch<T>) -> Int? {
        for index in 0..<_fetchs.count {
            if _fetchs[index] === fetch {
                return index
            }
        }
        return nil
    }
    
    var _changing: Bool = false
    var _flags: Set<String> = Set<String>(minimumCapacity:2)
    private func ssn_begin_change(_ flag: String) {
        if !_flags.contains(flag) {
            _flags.insert(flag)
            
            if !_changing {
                _changing = true
                
                if let delegate = _delegate {
                    delegate.ssn_controllerWillChangeContent(self)
                }
            }
        }
    }
    private func ssn_end_change(_ flag: String) {
        if _flags.contains(flag) {
            _flags.remove(flag)
            
            if _flags.count == 0 && _changing {
                _changing = false
                
                if let delegate = _delegate {
                    delegate.ssn_controllerDidChangeContent(self)
                }
            }
        }
    }
    
//    public func ssn_fetch(_ fetch: MMFetch<T>, _ updates: (() -> Bool)) {
//        guard let delegate = _delegate else {
//            updates()
//            return
//        }
////        delegate.
//    }
    
    public func ssn_fetch_begin_change(_ fetch: MMFetch<T>) {
        ssn_begin_change("\(fetch)")
    }
    
    public func ssn_fetch_end_change(_ fetch: MMFetch<T>) {
        ssn_end_change("\(fetch)")
    }
    
    /// no data modify. just notice controller changes
    public func ssn_fetch(_ fetch: MMFetch<T>, didChange anObject: T?, at index: Int, for type: MMFetchChangeType, newIndex: Int) {
        guard let delegate = _delegate else {
            return
        }
        
        guard let section = self.indexOf(fetch) else { return }
        
        let indexPath = IndexPath(row:index,section:section)
        
        let flag = "FetchsInner"
        ssn_begin_change(flag)
        
        switch type {
        case MMFetchChangeType.insert:
//            _fetchs[index].insert(anObject, atIndex: index)
            delegate.ssn_controller!(self, didChange: anObject, at: indexPath, for: MMFetchChangeType.insert, newIndexPath: indexPath)
            break
        case MMFetchChangeType.delete:
            delegate.ssn_controller!(self, didChange: anObject, at: indexPath, for: MMFetchChangeType.delete, newIndexPath: indexPath)
            break
        case MMFetchChangeType.update:
            delegate.ssn_controller!(self, didChange: anObject, at: indexPath, for: MMFetchChangeType.update, newIndexPath: indexPath)
            break
        case MMFetchChangeType.move:
            delegate.ssn_controller!(self, didChange: anObject, at: indexPath, for: MMFetchChangeType.move, newIndexPath: IndexPath(row:newIndex,section:section))
            break
        }
        
        ssn_end_change(flag)
    }
    fileprivate func generateCell(_ view: UIScrollView, cellForRowAt indexPath: IndexPath, isSupplementary:Bool = false) -> UIView {
        let cell = _generateCell(view, cellForRowAt: indexPath, isSupplementary: isSupplementary)
        let point = Unmanaged<AnyObject>.passUnretained(cell as AnyObject).toOpaque()
        print(">>" + String(describing: type(of: cell)) + " 0x\(String(format:"%2X", point.hashValue))")
        return cell
    }
    fileprivate func _generateCell(_ view: UIScrollView, cellForRowAt indexPath: IndexPath, isSupplementary:Bool = false) -> UIView {
        // 使用普通方式创建cell
        var cellID = "cell"
        var isFloating = false
        
        var table:UITableView? = nil
        var collection:UICollectionView? = nil
        var cell:UIView? = nil
        if view is UITableView {
            table = (view as? UITableView)
        } else if (view is UICollectionView) {
            collection = (view as? UICollectionView)
        }
        
        guard let model = self[indexPath.section]?[indexPath.row] else {
            cell = generateDefaultCell(view, cellForRowAt: indexPath, isSupplementary: isSupplementary)
            cell?.ssn_weak_set_fetchs(self as AnyObject)
            return cell!
        }
        
        cellID = model.ssn_cellID()
        if cellID.isEmpty {
            cellID = ".auto." + String(describing: type(of: model))
        }
        isFloating = model.ssn_canFloating()
        
        //出现错位的情况返回兼容的cell
        if (isFloating && !isSupplementary) || (!isFloating && isSupplementary) {
            cell = generateDefaultCell(view, cellForRowAt: indexPath, isSupplementary: isSupplementary)
            cell?.ssn_weak_set_fetchs(self as AnyObject)
            return cell!
        }
        
        
        // 1.创建cell,此时cell是可选类型
        if let table = table {
            if isFloating {
                cell = table.dequeueReusableHeaderFooterView(withIdentifier:cellID)
            } else {
                cell = table.dequeueReusableCell(withIdentifier:cellID)
            }
            cell?.ssn_weak_set_fetchs(self as AnyObject)
        }
        
        // 2.判断cell是否为nil
        if cell == nil {
            if table != nil && model.responds(to: #selector(MMCellModel.ssn_cell(_:))) {
                MMTry.try({
                    cell = model.ssn_cell!(cellID)
                }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
            } else if model.responds(to: #selector(MMCellModel.ssn_cellNib(_:isFloating:))) {
                if !_isRgst.contains(cellID) {
                    _isRgst.insert(cellID)
                    MMTry.try({
                        let nib = model.ssn_cellNib!(cellID,isFloating: isFloating)
                        if table != nil {
                            if isFloating {//只做header
                                table?.register(nib, forHeaderFooterViewReuseIdentifier: cellID)
                            } else {
                                table?.register(nib, forCellReuseIdentifier: cellID)
                            }
                        } else {
                            if isFloating {
                                collection?.register(nib, forSupplementaryViewOfKind: COLLECTION_HEADER_KIND, withReuseIdentifier: cellID)
                            } else {
                                collection?.register(nib, forCellWithReuseIdentifier: cellID)
                            }
                        }
                    }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
                }
                MMTry.try({
                    if table != nil {
                        if isFloating {//只做header
                            cell = table?.dequeueReusableHeaderFooterView(withIdentifier: cellID)
                        } else {
                            cell = table?.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
                        }
                    } else {
                        if isFloating {
                            cell = collection?.dequeueReusableSupplementaryView(ofKind: COLLECTION_HEADER_KIND, withReuseIdentifier: cellID, for: indexPath)
                        } else {
                            cell = collection?.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath)
                        }
                    }
                }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
            } else if model.responds(to: #selector(MMCellModel.ssn_cellClass(_:isFloating:))) {
                if !_isRgst.contains(cellID) {
                    _isRgst.insert(cellID)
                    MMTry.try({
                        let clz:AnyClass = model.ssn_cellClass!(cellID,isFloating: isFloating)
                        if table != nil {
                            if isFloating {//只做header
                                table?.register(clz, forHeaderFooterViewReuseIdentifier: cellID)
                            } else {
                                table?.register(clz, forCellReuseIdentifier: cellID)
                            }
                        } else {
                            if isFloating {
                                collection?.register(clz, forSupplementaryViewOfKind: COLLECTION_HEADER_KIND, withReuseIdentifier: cellID)
                            } else {
                                collection?.register(clz, forCellWithReuseIdentifier: cellID)
                            }
                        }
                    }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
                }
                MMTry.try({
                    if table != nil {
                        if isFloating {//只做header
                            cell = table?.dequeueReusableHeaderFooterView(withIdentifier: cellID)
                        } else {
                            cell = table?.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
                        }
                    } else {
                        if isFloating {
                            cell = collection?.dequeueReusableSupplementaryView(ofKind: COLLECTION_HEADER_KIND, withReuseIdentifier: cellID, for: indexPath)
                        } else {
                            cell = collection?.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath)
                        }
                    }
                }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
            }
            cell?.ssn_weak_set_fetchs(self as AnyObject)
        }
        
        if cell == nil {
            cell = generateDefaultCell(view, cellForRowAt: indexPath, isSupplementary: isSupplementary)
            cell?.ssn_weak_set_fetchs(self as AnyObject)
        }
        
        // 3.设置cell数据
        MMTry.try({
            let reused = model.isEqual(cell?.ssn_cellModel)
            cell?.ssn_set_cellModel(model) //提前设置model的值
            cell?.ssn_onDisplay(view, model: model, atIndexPath: indexPath, reused: reused)
        }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
        
        return cell!
    }
    
    fileprivate func generateDefaultCell(_ view: UIScrollView, cellForRowAt indexPath: IndexPath, isSupplementary:Bool = false) -> UIView {
        var table:UITableView? = nil
        var collection:UICollectionView? = nil
        var cell:UIView? = nil
        if view is UITableView {
            table = (view as? UITableView)
        } else if (view is UICollectionView) {
            collection = (view as? UICollectionView)
        }
        
        if table != nil {
            if isSupplementary {
                cell = UITableViewHeaderFooterView(reuseIdentifier: DEFAULT_HEAD_ID)
            } else {
                cell = UITableViewCell(style: .default, reuseIdentifier: DEFAULT_CELL_ID)
            }
        } else {
            if isSupplementary {
                if !_isRgst.contains(DEFAULT_HEAD_ID) {
                    _isRgst.insert(DEFAULT_HEAD_ID)
                    collection?.register(UICollectionReusableView.self, forSupplementaryViewOfKind: COLLECTION_HEADER_KIND, withReuseIdentifier: DEFAULT_HEAD_ID)
                }
                cell = collection?.dequeueReusableSupplementaryView(ofKind: COLLECTION_HEADER_KIND, withReuseIdentifier: DEFAULT_HEAD_ID, for: indexPath)
            } else {
                if !_isRgst.contains(DEFAULT_CELL_ID) {
                    _isRgst.insert(DEFAULT_CELL_ID)
                    collection?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DEFAULT_CELL_ID)
                }
                cell = collection?.dequeueReusableCell(withReuseIdentifier: DEFAULT_CELL_ID, for: indexPath)
            }
        }
        
        return cell!
    }
    
    // MARK UIUICollectionViewDataSource
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        let s = _fetchs.count
//        print("section:\(s)")
        return s
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fetch = self[section] {
            let c = fetch.count()
//            print("section:\(section) row:\(c)")
            return c
        } else {
            return 0
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = generateCell(collectionView, cellForRowAt: indexPath)  as? UICollectionViewCell {
            return cell
        }
        return UICollectionViewCell()
    }
    
    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if let cell = generateCell(collectionView, cellForRowAt: indexPath, isSupplementary: true)  as? UICollectionReusableView {
            return cell
        }
        return UICollectionReusableView()
    }
    
    // MARK UITableViewDataSource
    public func numberOfSections(in tableView: UITableView) -> Int {// section个数
        return _fetchs.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetch = self[section] {
            return fetch.count()
        } else {
            return 0
        }
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = generateCell(tableView, cellForRowAt: indexPath) as? UITableViewCell {
            return cell
        }
        return UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self[section]?.title
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return generateCell(tableView, cellForRowAt: IndexPath(row: 0, section: section), isSupplementary: true)
    }
    
    public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return self[section]?.footer
    }
    
    
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let rt = self[indexPath.section]?[indexPath.row]?.ssn_canEdit() {
            return rt
        }
        return false
    }
    
    // Moving/reordering
    
    // Allows the reorder accessory view to optionally be shown for a particular row. By default, the reorder control will be shown only if the datasource implements -tableView:moveRowAtIndexPath:toIndexPath:
    public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if let rt = self[indexPath.section]?[indexPath.row]?.ssn_canMove() {
            return rt
        }
        return false
    }
    
    // Index
    
    // return list of section titles to display in section index view (e.g. "ABCD...Z#")
//    public func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]? { return nil}
    
    // // tell table which section corresponds to section title/index (e.g. "B",1))
//    public func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {return 0}
    
    // Data manipulation - insert and delete support
    public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        var rt: Bool = false
        if let delegate = _delegate {
            if delegate.responds(to: #selector(MMFetchsControllerDelegate.ssn_controller(_:tableView:commitEditingStyle:forRowAtIndexPath:))) {
                MMTry.try({
                    rt = delegate.ssn_controller!(self, tableView: tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
                }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
            }
        }
        if !rt {
            //default delete cell
            if (editingStyle == UITableViewCellEditingStyle.delete) {
                //add code here for when you hit delete
                _ = self[indexPath.section]?.delete(indexPath.row)
                /// the action delete cell will do at notice call back
//                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)//
            }
        }
    }
    
    // Data manipulation - reorder / moving support
    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if let delegate = _delegate {
            if delegate.responds(to: #selector(MMFetchsControllerDelegate.ssn_controller(_:tableView:moveRowAtIndexPath:toIndexPath:))) {
                MMTry.try({
                    delegate.ssn_controller!(self, tableView: tableView, moveRowAtIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
                }, catch: { (exception) in print("error:\(String(describing: exception))") }, finally: nil)
            }
        }
    }
}


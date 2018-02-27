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
@objc public protocol MMCellModel : AnyObject {
    func ssn_cellID() -> String
    func ssn_cell(_ cellID : String) -> UITableViewCell
    func ssn_canEdit() -> Bool
    func ssn_canMove() -> Bool
    func ssn_cellHeight() -> Float //UITableViewDelegate heightForRowAt or UICollectionViewLayout layoutAttributesForItemAtIndexPath
    func ssn_canFloating() -> Bool
    func ssn_isExclusiveLine() -> Bool
    func ssn_cellGridSpanSize() -> UInt //占用列数
}

private var CELL_MODEL_PROPERTY = 0

/// UITableViewCell display support
extension UITableViewCell {
    
    @objc var ssn_cellModel : MMCellModel? {
        get{
            guard let result = objc_getAssociatedObject(self, &CELL_MODEL_PROPERTY) as? MMCellModel else {  return nil }
            return result
        }
//        set{
//            objc_setAssociatedObject(self, &CELL_MODEL_PROPERTY, newValue, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN))
//        }
    }
    
//    func prepareForReuse()
    @objc func ssn_onDisplay(_ tableView: UITableView, model: AnyObject,atIndexPath indexPath: IndexPath) {}
    
    fileprivate func ssn_set_cellModel(_ model:MMCellModel?) {
        objc_setAssociatedObject(self, &CELL_MODEL_PROPERTY, model, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

/// UICollectionReusableView display support
extension UICollectionReusableView {
    @objc var ssn_cellModel : MMCellModel? {
        get{
            guard let result = objc_getAssociatedObject(self, &CELL_MODEL_PROPERTY) as? MMCellModel else {  return nil }
            return result
        }
    }
    
    //    func prepareForReuse()
    @objc func ssn_onDisplay(_ tableView: UICollectionView, model: AnyObject,atIndexPath indexPath: IndexPath) {}
    
    fileprivate func ssn_set_cellModel(_ model:MMCellModel?) {
        objc_setAssociatedObject(self, &CELL_MODEL_PROPERTY, model, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}

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
    public final subscript (index: Int) -> T? { get{ return self.get(index)} set(newValue) { if newValue != nil {self.insert(newValue!, atIndex: index)}} }
    
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
        let model = self.get(predicate)
        if model != nil {
            return indexOf(model!)
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
    
}

/// Listening the fetch controller changes
@objc public protocol MMFetchsControllerDelegate {
    
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
    @objc optional func ssn_controller(_ controller: AnyObject, tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: IndexPath) -> Bool
    
    // Data manipulation - reorder / moving support
    @objc optional func ssn_controller(_ controller: AnyObject, tableView: UITableView, moveRowAtIndexPath sourceIndexPath: IndexPath, toIndexPath destinationIndexPath: IndexPath)
}

/**
 *
 */
public class MMFetchsController<T: MMCellModel> : NSObject,UITableViewDataSource /*,UITableViewDelegate*/ {
    
    var _fetchs = [] as [MMFetch<T>]
    
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
    public init(fetchs: [MMFetch<T>]) {
        super.init()
        _fetchs = fetchs
        for fetch in fetchs {
            fetch._listener = self
        }
    }
    
    /// The number of Fetchs in the controller.
    public func count() -> Int {
        return _fetchs.count
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
        self[indexPath.section]?.delete(indexPath.row)
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
                
                if _delegate != nil {
                    _delegate!.ssn_controllerWillChangeContent(self)
                }
            }
        }
    }
    private func ssn_end_change(_ flag: String) {
        if _flags.contains(flag) {
            _flags.remove(flag)
            
            if _flags.count == 0 && _changing {
                _changing = false
                
                if _delegate != nil {
                    _delegate!.ssn_controllerDidChangeContent(self)
                }
            }
        }
    }
    
    public func ssn_fetch_begin_change(_ fetch: MMFetch<T>) {
        ssn_begin_change("\(fetch)")
    }
    
    public func ssn_fetch_end_change(_ fetch: MMFetch<T>) {
        ssn_end_change("\(fetch)")
    }
    
    /// no data modify. just notice controller changes
    public func ssn_fetch(_ fetch: MMFetch<T>, didChange anObject: T?, at index: Int, for type: MMFetchChangeType, newIndex: Int) {
        if _delegate == nil {
            return
        }
        
        let section = self.indexOf(fetch)
        if section == nil {
            return
        }
        
        let indexPath = IndexPath(row:index,section:section!)
        
        let flag = "FetchsInner"
        ssn_begin_change(flag)
        
        switch type {
        case MMFetchChangeType.insert:
//            _fetchs[index].insert(anObject, atIndex: index)
            _delegate?.ssn_controller!(self, didChange: anObject, at: indexPath, for: MMFetchChangeType.insert, newIndexPath: indexPath)
            break
        case MMFetchChangeType.delete:
            _delegate?.ssn_controller!(self, didChange: anObject, at: indexPath, for: MMFetchChangeType.delete, newIndexPath: indexPath)
            break
        case MMFetchChangeType.update:
            _delegate?.ssn_controller!(self, didChange: anObject, at: indexPath, for: MMFetchChangeType.update, newIndexPath: indexPath)
            break
        case MMFetchChangeType.move:
            _delegate?.ssn_controller!(self, didChange: anObject, at: indexPath, for: MMFetchChangeType.move, newIndexPath: IndexPath(row:newIndex,section:section!))
            break
        }
        
        ssn_end_change(flag)
    }
    
    
    // MARK UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let fetch = self[section] {
            return fetch.count()
        } else {
            return 0
        }
    }
    
    // section个数
    public func numberOfSections(in tableView: UITableView) -> Int {
        return _fetchs.count
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        
        // ----------------------------------------------------------------
        // 使用普通方式创建cell
        var cellID = "cell"
        let model = self[indexPath.section]?[indexPath.row]
        if model != nil {
            cellID = model!.ssn_cellID()
        }
        
        
        // 1.创建cell,此时cell是可选类型
        var cell = tableView.dequeueReusableCell(withIdentifier:cellID)
        
        // 2.判断cell是否为nil
        if cell == nil {
            MMTry.try({ do {
                cell = try model?.ssn_cell(cellID)
            } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        }
        
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellID)
        }
        
        // 3.设置cell数据
        if model != nil {
            MMTry.try({ do {
                cell?.ssn_set_cellModel(model)//提前设置model的值
                try cell!.ssn_onDisplay(tableView, model: model!, atIndexPath: indexPath)
            } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        }
        
        return cell!
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self[section]?.title
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
        if _delegate != nil {
            MMTry.try({ do {
                rt = try self._delegate!.ssn_controller!(self, tableView: tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: indexPath)
            } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
        }
        if !rt {
            //default delete cell
            if (editingStyle == UITableViewCellEditingStyle.delete) {
                //add code here for when you hit delete
                self[indexPath.section]?.delete(indexPath.row)
                /// the action delete cell will do at notice call back
//                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)//
            }
        }
    }
    
    // Data manipulation - reorder / moving support
    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        MMTry.try({ do {
            try self.delegate?.ssn_controller!(self, tableView: tableView, moveRowAtIndexPath: sourceIndexPath, toIndexPath: destinationIndexPath)
        } catch { print("error:\(error)") } }, catch: { (exception) in print("error:\(exception)") }, finally: nil)
    }
}

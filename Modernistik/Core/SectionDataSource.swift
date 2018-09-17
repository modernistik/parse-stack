//
//  SectionDataSource.swift
//  Modernistik
//
//  Created by Anthony Persaud on 9/17/18.
//

import Foundation

// MARK: SectionDataSource
public protocol SectionDataSource: class {
    /**
     Return the number of rows for this data source.
     */
    var numberOfRows:Int { get }
    /**
     Configure the data source for a tableView. This method should be overriden to register any specific UITableViewCell subclasses
     that this data source needs.
     
     - parameters:
     - tableView: The tableView to configure
     */
    func configure(tableView:UITableView)
    /**
     Return the tableView cell height for this particular row. By default, this returns `UITableViewAutomaticDimension`.
     */
    func heightForRow(row:Int) -> CGFloat
    /**
     This method should be implemented to return the corresponding configured cell subclass to display for a particular row.
     
     - parameters:
     - row: The row number based on the indexPath
     - tableView: The tableView requesting the cell.
     */
    func cellForRow(row:Int, usingTableView tableView:UITableView) -> UITableViewCell
    /// A hook to perform an action when a selected row in the data source is selected.
    func tableView(tableView:UITableView, didSelectRow row:Int)
    /// A hook to perform an action when a selected row's accessory is selected.
    func tableView(tableView:UITableView, didSelectAccessoryAtRow row:Int)
}

extension SectionDataSource {
    public var numberOfRows:Int { return 0 }
    public func configure(tableView:UITableView) { }
    public func heightForRow(row:Int) -> CGFloat { return UITableView.automaticDimension }
    public func tableView(tableView:UITableView, didSelectRow row:Int) {}
    public func tableView(tableView:UITableView, didSelectAccessoryAtRow row:Int) {}
}

// MARK: SectionIndexType
/**
 This enum-protocol provides the type for setting up section items in the menu.
 */
public protocol SectionIndexType : RawRepresentable, IntRepresentable {
    init?(rawValue: Int)
    var title:String { get }
}

extension SectionIndexType {
    
    public var title:String {
        return String(describing: self)
    }
}

final
public class EmptySectionDataSource : SectionDataSource {
    public init() {}
    public var numberOfRows:Int { return 0 }
    public func heightForRow(row:Int) -> CGFloat { return UITableView.automaticDimension }
    
    public func cellForRow(row:Int, usingTableView tableView:UITableView) -> UITableViewCell {
        return UITableViewCell(style: .default, reuseIdentifier: "EmptyProfileDataSourceCell")
    }
    
    public func tableView(tableView:UITableView, didSelectRow row:Int) {}
}

//
//  SectionDataSource.swift
//  Modernistik
//
//  Created by Anthony Persaud on 9/17/18.
//

import Foundation
import UIKit
/**
 This protocol represents a software design pattern for managing multiple sections in a
 UITableView that may display different content with different UITableViewCells.

 The idea is for each section of a table view to have its own SectionDataSource
 class that would receive forwarding calls from the main table view data source and delegate
 with the methods provided. Each SectionDataSource would then respond with the appropriate values back to the callee.

 Doing this, modularizes the layout of a table view into discrete sections, allowing the main data source and delegate to the tableView to
 only managing the current section that is being presented in order to pick the right SectionDataSource class to forward the calls.

 # Example
 ```
 class NamesDataSource : SectionDataSource {

    // some internal data (up to you to manage)
    var names = [String]()

    var count: Int {
        // return the total number of rows to display
        return names.count
    }

    // register some cells to dequeue later on.
    func configure(tableView:UITableView) {
        ModernTableCell.register(withTableView: tableView)
    }

    // Implement this method to return the proper cell based on the requested row.
    func cell(forRow:Int, usingTableView tableView:UITableView) -> UITableViewCell {
        let cell = ModernTableCell.dequeueReusableCell(inTableView: tableView)
        cell.textLabel?.text = names[row]
        return cell
    }
 }

 ```

 To implement this section data source pattern in your main UIViewController, you can use the template below.

 ```swift
 // not limited to UITableViewController
 class MyViewController : UITableViewController {

    // create data sources
    let dataSource1 = NamesDataSource()
    let dataSource2 = NamesDataSource()

    // helper
    func data(for section:Int) -> SectionDataSource {
        return section == 0 ? dataSource1 : dataSource2
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource1.names = ["Tony","Steve","Thor"]
        dataSource2.names = ["Thanos","Galactus"]

        // configure
        dataSource1.configure(tableView: tableView)
        dataSource2.configure(tableView: tableView)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // only two: [dataSource1, datasource2]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let ds = data(for: section)
        return ds.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let ds = data(for: indexPath.section)
        return ds.height(forRow: indexPath.row)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // select the right data source
        let ds = data(for: indexPath.section)
        return ds.cell(forRow: indexPath.row, usingTableView:tableView)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ds = data(for: indexPath.section)
        // forward the call
        ds.tableView(tableView, didSelectRow: indexPath.row)
    }

 }
 ```

 */
public protocol SectionDataSource: AnyObject {
    /**
     Return the number of rows for this data source. Normally this method should be called whenever you need the number of rows for
     the section representing this data source. Defaults to 0.
     */
    var count: Int { get }

    /**
     Configure the data source for a tableView. This method should be overriden to register any specific UITableViewCell subclasses
     that this data source needs. You may configure multiple tableView with the same data source if the action performed in this
     method is idempotent.
     # Example
     ```
     dataSource.configure(tableView: tableView)
     ```
     - parameter tableView: The tableView to configure.
     */
    func configure(with tableView: UITableView)
    /**
     Return the tableView cell height for this particular row. By default, this returns `UITableView.automaticDimension`. This
     method can also be used in table view data sources for sending estimated heights.
     - parameter row: The row number for in the table view section.
     - returns: The preferred height for the cell in this row.
     */
    func height(forRow row: Int) -> CGFloat
    /**
     This method should be implemented to return the corresponding configured cell subclass to display for a particular row. Normally,
     in your tableView data source method, you should verify you are in the proper section to display cells for this data source. Also,
     you should have used `configure(tableView:)` to configure the tableView to support these cells

     - parameter row: The row number based on the indexPath.
     - parameter tableView: The tableView requesting the cell.
     */
    func cell(forRow row: Int, in tableView: UITableView) -> UITableViewCell
    /**
     A hook to perform an action when a selected row in the data source is selected. Normally this should be called
     in your table view delegate method for cell selection.
     - parameter row: The row number that was selected.
     - parameter tableView: The tableView in which the selection ocurred.
     */
    func selected(row: Int, in tableView: UITableView)

    /**
     A hook to perform an action when a selected row's accessory is selected. Normally this should be called
     in your table view delegate method for cell accessory selection.

     - parameter tableView: The tableView in which the selection ocurred.
     - parameter row: The row number that was selected.
     */
    func selected(accessoryRow: Int, in tableView: UITableView)
}

extension SectionDataSource {
    /// Alias for `count`.
    public var numberOfRows: Int { return count }
    public func height(forRow _: Int) -> CGFloat { return UITableView.automaticDimension }
    public func selected(row _: Int, in _: UITableView) {}
    public func selected(accessoryRow _: Int, in _: UITableView) {}
    public func tableView(_ tableView: UITableView, didSelectRow row: Int) { selected(row: row, in: tableView) }
    public func tableView(_ tableView: UITableView, didSelectAccessoryAtRow row: Int) { selected(accessoryRow: row, in: tableView) }
}

// MARK: SectionIndexType

/**
 This enum-protocol provides the type for setting up section items in the menu.
 */
public protocol SectionIndexType: RawRepresentable, IntRepresentable {
    init?(rawValue: Int)
    var title: String { get }
}

extension SectionIndexType {
    public var title: String {
        return String(describing: self)
    }
}

/**
 A basic class that implements SectionDataSource. This class returns that it has no data. It is useful as a starting point in
 how to implement you own class.
 */
public final
class EmptySectionDataSource: SectionDataSource {
    public init() {}
    public var count: Int { return 0 }
    public func configure(with tableView: UITableView) {
        ModernTableCell.register(with: tableView)
    }

    public func height(forRow _: Int) -> CGFloat { return UITableView.automaticDimension }
    public func cell(forRow _: Int, in tableView: UITableView) -> UITableViewCell {
        return ModernTableCell.dequeueReusableCell(in: tableView)
    }
}

public protocol CollectionDataSource: AnyObject {
    var count: Int { get }
    func configure(with collectionView: UICollectionView)
    func sizeForItemAt(indexPath: IndexPath, inLayout collectionViewLayout: UICollectionViewLayout) -> CGSize
    func cell(for indexPath: IndexPath, in collectionView: UICollectionView) -> UICollectionViewCell
    func selectedItem(at indexPath: IndexPath, in collectionView: UICollectionView)
}

extension CollectionDataSource {
    /// Alias for `count`.
    public var numberOfItems: Int { return count }
    public func selectedItem(at _: IndexPath, in _: UICollectionView) {}
}

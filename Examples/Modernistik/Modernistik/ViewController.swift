//
//  ViewController.swift
//  SlateExample
//
//  Created by Anthony Persaud on 1/1/18.
//  Copyright © 2018 Modernistik LLC. All rights reserved.
//

import UIKit
import Modernistik

class NamesDataSource : SectionDataSource {
    
    // some internal data (up to you to manage)
    var names = [String]()
    
    var count: Int {
        // return the total number of rows to display
        return names.count
    }
    
    // register some cells to dequeue later on.
    func configure(with tableView:UITableView) {
        ModernTableCell.register(with: tableView)
    }
    
    // Implement this method to return the proper cell based on the requested row.
    func cell(forRow row:Int, in tableView:UITableView) -> UITableViewCell {
        let cell = ModernTableCell.dequeueReusableCell(in: tableView)
        
        cell.textLabel?.text = names[row]
        return cell
    }
}

class ViewController : UITableViewController {
    
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
        dataSource1.configure(with: tableView)
        dataSource2.configure(with: tableView)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // only two: [dataSource1, datasource2]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let ds = data(for: section)
        return ds.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let ds = data(for: indexPath.section)
        return ds.height(forRow: indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // select the right data source
        let ds = data(for: indexPath.section)
        return ds.cell(forRow: indexPath.row, in:tableView)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ds = data(for: indexPath.section)
        // forward the call
        ds.tableView(tableView, didSelectRow: indexPath.row)
    }
    
}

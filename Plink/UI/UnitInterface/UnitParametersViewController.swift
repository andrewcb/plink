//
//  UnitParametersViewController.swift
//  Plink
//
//  Created by acb on 08/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

class UnitParametersViewController: NSViewController, AcceptsAUInstance {
    var audioUnitInstance: AudioUnitInstance?
    var paramInfo: [AudioUnitInstance.ParameterInfo]?
    
    @IBOutlet var tableView: NSTableView!
    
    override func viewWillAppear() {
        self.paramInfo = self.audioUnitInstance.flatMap { try? $0.getAllParameterInfo(forScope: kAudioUnitScope_Global) }
        self.tableView.reloadData()
        
    }
}

extension UnitParametersViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.paramInfo?.count ?? 0
    }
}

extension UnitParametersViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < paramInfo?.count ?? 0, let paramInfo = self.paramInfo?[row] else { return nil }
        var cellIdentifier: String
        var contents: String
        if tableColumn == self.tableView.tableColumns[0] {
            cellIdentifier = "NameCell"
            contents = paramInfo.name ?? "-"
        } else { // column 1
            cellIdentifier = "ValueCell"
            do {
                if let val = try self.audioUnitInstance?.getParameterValue(paramInfo.id, scope: kAudioUnitScope_Global, element: 0) {
                    contents = "\(val)"
                } else {
                    contents = ""
                }
            } catch {
                contents = ":-/"

            }
        }
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = contents
            return cell
        }
        return nil
    }
}

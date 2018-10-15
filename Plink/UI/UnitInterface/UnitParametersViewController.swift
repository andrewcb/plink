//
//  UnitParametersViewController.swift
//  Plink
//
//  Created by acb on 08/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

class UnitParameterNameCell: NSTableCellView {
    
}
class UnitParameterValueCell: NSTableCellView {
    var value: AudioUnitParameterValue? = nil {
        didSet {
            self.textField?.stringValue = self.value.map { "\($0)" } ?? "?"
        }
    }
}

class UnitParametersViewController: NSViewController, AcceptsAUInstance {
    var audioUnitInstance: ManagedAudioUnitInstance?
    var paramInfo: [AudioUnitInstanceBase.ParameterInfo]?
    
    private var listenerId: Int?
    
    @IBOutlet var tableView: NSTableView!
    
    override func viewWillAppear() {
        self.paramInfo = self.audioUnitInstance.map { $0.allParameterInfo(forScope: kAudioUnitScope_Global) }
        self.listenerId = self.audioUnitInstance?.addParameterValueListener({ (inst, paramId, scope, elem, val) in
            self.tableView.reloadData()
        })
        self.tableView.reloadData()
        
    }
    
    override func viewWillDisappear() {
        if let listenerId = self.listenerId {
            self.audioUnitInstance?.removeParameterValueListener(withID: listenerId)
        }
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
        if tableColumn == self.tableView.tableColumns[0] {
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NameCell"), owner: nil) as? UnitParameterNameCell
            cell?.textField?.stringValue = paramInfo.name ?? "-"
            return cell
        } else { // column 1
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ValueCell"), owner: nil) as? UnitParameterValueCell
            cell?.value = (try? self.audioUnitInstance?.getParameterValue(paramInfo.id, scope: kAudioUnitScope_Global, element: 0)).flatMap { $0 }
            return cell
        }
    }
}

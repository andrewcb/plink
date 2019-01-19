//
//  CycleListViewController.swift
//  Plink
//
//  Created by acb on 13/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Foundation

class CycleColumnCell: NSTableCellView {
    var index: Int = 0
    func fill(from cycle: ScoreModel.Cycle) { }
    var onChange: ((Int, String?, Bool?, TickDuration?, TickTime?, ScoreModel.CuedAction?)->())?
}

class CycleNameCell: CycleColumnCell {
    override func fill(from cycle: ScoreModel.Cycle) {
        self.textField?.stringValue = cycle.name
    }
    
    @IBAction func valueChanged(_ sender: Any) {
        guard let textField = self.textField, sender as? NSTextField == textField else { return }
        self.onChange?(self.index, textField.stringValue, nil, nil, nil, nil)
    }
}

class CycleIsActiveCell: CycleColumnCell {
    @IBOutlet var checkBox: NSButton!
    
    override func fill(from cycle: ScoreModel.Cycle) {
        self.checkBox.state = cycle.isActive ? .on : .off
    }
    
    @IBAction func valueChanged(_ sender: Any) {
        guard let checkBox = self.checkBox, sender as? NSButton == checkBox else { return }
        self.onChange?(self.index, nil, self.checkBox.state == .on, nil, nil, nil)
    }
}

// a common superclass of Period and Modulus
class CycleTimeValueCell: CycleColumnCell {
    var time: TickTime = 0
    func getValue(from cycle: ScoreModel.Cycle) -> TickTime {
        fatalError("Override this")
    }
    func callOnChange(_ value: TickTime) { }
    override func fill(from cycle: ScoreModel.Cycle) {
        self.time = self.getValue(from: cycle)
        self.textField?.stringValue = TickTimeFormattingService.sharedInstance.format(time: self.time)
    }
    
    @IBAction func valueChanged(_ sender: Any) {
        guard let textField = self.textField, sender as? NSTextField == textField else { return }
        guard let time = TickTimeFormattingService.sharedInstance.parse(string: textField.stringValue) else {
            print("Badly formatted time: \(self.textField!.stringValue)")
            textField.stringValue = TickTimeFormattingService.sharedInstance.format(time: self.time)
            return
        }
        self.time = time
        self.callOnChange(time)
    }
}

class CyclePeriodCell: CycleTimeValueCell {
    override func getValue(from cycle: ScoreModel.Cycle) -> TickTime { return cycle.period }
    override func callOnChange(_ value: TickTime) { self.onChange?(self.index, nil, nil, value, nil, nil) }
}

class CycleModulusCell: CycleTimeValueCell {
    override func getValue(from cycle: ScoreModel.Cycle) -> TickTime { return cycle.modulus }
    override func callOnChange(_ value: TickTime) { self.onChange?(self.index, nil, nil, nil, value, nil) }
}

class CycleActionCell: CycleColumnCell {
    override func fill(from cycle: ScoreModel.Cycle) {
        switch(cycle.action) {
        case .codeStatement(let cs): self.textField?.stringValue = cs
        case .callProcedure(let proc): self.textField?.stringValue = proc
        }
    }
    @IBAction func valueChanged(_ sender: Any) {
        guard let textField = self.textField, sender as? NSTextField == textField else { return }
        let action = ScoreModel.CuedAction(codeText: textField.stringValue)
        self.onChange?(self.index, nil, nil, nil, nil, action)
    }
}

class CycleListViewController: ScoreItemListViewController {
    
    fileprivate let rowPasteboardType = NSPasteboard.PasteboardType("private.row")
    
    var cycleList: [ScoreModel.Cycle] = []
    
    fileprivate func cellChanged(_ index: Int, _ name: String?, _ isActive: Bool?, _ period: TickDuration?, _ modulus: TickTime?, _ action: ScoreModel.CuedAction?) {
        guard let transport = self.activeDocument?.transport else { return }
        let oldCycle = self.cycleList[index]
        let newCycle = ScoreModel.Cycle(name: name ?? oldCycle.name, isActive: isActive ?? oldCycle.isActive, period: period ?? oldCycle.period, modulus: modulus ?? oldCycle.modulus, action: action ?? oldCycle.action)
//        print("Changed: \(oldCycle) => \(newCycle)")
        self.cycleList[index] = newCycle
        transport.score.replaceCycle(atIndex: index, with: newCycle)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerForDraggedTypes([rowPasteboardType])
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.cycleList = self.activeDocument?.transport.score.cycleList ?? []
        self.tableView.reloadData()

        NotificationCenter.default.addObserver(self, selector: #selector(self.cycleListChanged(_:)), name: Transport.cyclesChanged, object: nil)
    }

    @objc func cycleListChanged(_ notification: Notification) {
        guard let transport = self.activeDocument?.transport else { return }
        DispatchQueue.main.async {
            let their = transport.score.cycleList
            let our = self.cycleList
            if our != their {
                self.cycleList = their
                self.tableView.reloadData()
            }
        }
    }
    
    override func addItem() {
        guard let transport = self.activeDocument?.transport else { return }
        let newName = "cycle\(self.cycleList.count + 1)"
        let newCycle = ScoreModel.Cycle(name: newName, isActive: true, period: TickTime(beats: 1, ticks: 0), modulus: TickTime(0), action: .codeStatement(""))
        self.cycleList.append(newCycle)
        transport.score.add(cycle: newCycle)
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) { [weak self] in
            let index = (self?.cycleList.count ?? 0) - 1
            guard index >= 0 else { return }
            self?.tableView.scrollRowToVisible(index)
            self?.tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
    }
}


extension CycleListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.cycleList.count
    }

    //MARK: drag and drop for reordering
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        item.setString("\(row)", forType: rowPasteboardType)
        return item
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        return dropOperation == .above ? .move : []
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        let oldIndices = info.enumeratedPasteboardItemData(for: tableView, forType: self.rowPasteboardType) { Int($0) }
        
        guard
            let oldIndex = oldIndices.first,
            let transport = self.activeDocument?.transport
        else { return false }
        
        let dest = (oldIndex>row) ? row : row-1
        tableView.moveRow(at: oldIndex, to: dest)
        
        let temp = self.cycleList[dest]
        self.cycleList[dest] = self.cycleList[oldIndex]
        self.cycleList[oldIndex] = temp
        
        transport.score.moveCycle(at: oldIndex, to: dest)
        
        return true
    }
}

extension CycleListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < self.cycleList.count else { fatalError("Invalid row") }
        let cycle = self.cycleList[row]
        guard
            let id = tableColumn?.identifier,
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: id.rawValue+"Cell"), owner: nil)
        else { fatalError("Unable to make cycle column cell")}
        guard let ccell = cell as? CycleColumnCell else { return cell }
        ccell.index = row
        ccell.fill(from: cycle)
        ccell.onChange = self.cellChanged
        return ccell
    }
    
    func tableView(_ tableView: NSTableView, shouldReorderColumn columnIndex: Int, toColumn newColumnIndex: Int) -> Bool {
        print("reorder: ")
        return false
    }
}

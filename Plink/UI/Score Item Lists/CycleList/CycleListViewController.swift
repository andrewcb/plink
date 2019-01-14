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
    
    var cycleList: [ScoreModel.Cycle] = []
    
    fileprivate func cellChanged(_ index: Int, _ name: String?, _ isActive: Bool?, _ period: TickDuration?, _ modulus: TickTime?, _ action: ScoreModel.CuedAction?) {
        guard let transport = self.activeDocument?.transport else { return }
        let oldCycle = self.cycleList[index]
        let newCycle = ScoreModel.Cycle(name: name ?? oldCycle.name, isActive: isActive ?? oldCycle.isActive, period: period ?? oldCycle.period, modulus: modulus ?? oldCycle.modulus, action: action ?? oldCycle.action)
//        print("Changed: \(oldCycle) => \(newCycle)")
        self.cycleList[index] = newCycle
        if let newName = name {
            if oldCycle.name != newName {
                transport.score.renameCycle(from: oldCycle.name, to: newName)
            }
        } else {
            transport.score.set(cycle: newCycle, forName: newCycle.name)
        }
    }
    

    override func viewDidAppear() {
        super.viewDidAppear()
        self.cycleList = self.activeDocument?.transport.score.cycles.values.sorted(by: { $0.name < $1.name }) ?? []
        self.tableView.reloadData()

        NotificationCenter.default.addObserver(self, selector: #selector(self.cycleListChanged(_:)), name: Transport.cyclesChanged, object: nil)
    }

    @objc func cycleListChanged(_ notification: Notification) {
        guard let transport = self.activeDocument?.transport else { return }
        DispatchQueue.main.async {
            let their = transport.score.cycles.values.sorted(by: { $0.name < $1.name })
            let our = self.cycleList.sorted(by: { $0.name < $1.name })
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
        transport.score.set(cycle: newCycle, forName: newName)
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
}

extension CycleListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < self.cycleList.count else { fatalError("Invalid row") }
        let cycle = self.cycleList[row]
        guard
            let id = tableColumn?.identifier,
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: id.rawValue+"Cell"), owner: nil) as? CycleColumnCell
        else { fatalError("Unable to make cycle column cell")}
        cell.index = row
        cell.fill(from: cycle)
        cell.onChange = self.cellChanged
        return cell
    }
}

//
//  CueListViewController.swift
//  Plink
//
//  Created by acb on 02/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Cocoa


class CueColumnCell: NSTableCellView {
    var index: Int = 0
    func fill(from cue: ScoreModel.Cue) { }
    var onChange: ((Int, TickTime?, ScoreModel.CuedAction?)->())?
}

class CueTimeCell: CueColumnCell {
    var time: TickTime = 0
    override func fill(from cue: ScoreModel.Cue) {
        self.textField?.stringValue = TickTimeFormattingService.sharedInstance.format(time: cue.time)
        self.time = cue.time

    }
    
    @IBAction func valueChanged(_ sender: Any) {
        guard let textField = self.textField, sender as? NSTextField == textField else { return }
        guard let time = TickTimeFormattingService.sharedInstance.parse(string: textField.stringValue) else {
            print("Badly formatted time: \(self.textField!.stringValue)")
            textField.stringValue = TickTimeFormattingService.sharedInstance.format(time: self.time)
            return
        }
        self.time = time
        self.onChange?(self.index, time, nil)
    }

}

class CueActionCell: CueColumnCell {
    override func fill(from cue: ScoreModel.Cue) {
        switch(cue.action) {
        case .codeStatement(let cs): self.textField?.stringValue = cs
        case .callProcedure(let proc): self.textField?.stringValue = proc
        }
    }
    @IBAction func valueChanged(_ sender: Any) {
        guard let textField = self.textField, sender as? NSTextField == textField else { return }
        let action = ScoreModel.CuedAction(codeText: textField.stringValue)
        self.onChange?(self.index, nil, action)
    }
}

//extension CueActionCell: NSTextFieldDelegate {
//    func controlTextDidBeginEditing(_ obj: Notification) {
//        print("beginEditing: \(self.textField!.stringValue)")
//    }
//    func controlTextDidEndEditing(_ obj: Notification) {
//        print("endEditing: \(self.textField!.stringValue)")
//    }
//}

class CueListViewController: ScoreItemListViewController {
    
    var cueList: [ScoreModel.Cue] = []
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.cueList = self.activeDocument?.transport.score.cueList ?? []
        self.tableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(self.cueListChanged(_:)), name: Transport.cueListChanged, object: nil)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func cueListChanged(_ notification: Notification) {
        guard let transport = self.activeDocument?.transport else { return }
        DispatchQueue.main.async {
            let newCues = transport.score.cueList
            if newCues == self.cueList { return }
            self.cueList = newCues
            self.tableView.reloadData()
        }
    }
    
    fileprivate func cellChanged(_ index: Int, _ time: TickTime?, _ action: ScoreModel.CuedAction?) {
        guard let transport = self.activeDocument?.transport else { return }
        let oldCue = self.cueList[index]
        let newCue = ScoreModel.Cue(time: time ?? oldCue.time, action: action ?? oldCue.action)
        self.cueList[index] = newCue
        transport.score.replaceCue(atIndex: index, with: newCue)
    }
    
    override func addItem() {
        guard let transport = self.activeDocument?.transport else { return }
        let newCueTime = transport.score.cueList.last.map { $0.time+TickTime(beats: 1, ticks: 0)} ?? 0
        let newCue = ScoreModel.Cue(time: newCueTime, action: .codeStatement(""))
        transport.score.add(cue: newCue)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) { [weak self] in
            let index = transport.score.cueList.count - 1
            guard index >= 0 else { return }
            self?.tableView.scrollRowToVisible(index)
            self?.tableView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }
    }

}

extension CueListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.activeDocument?.transport.score.cueList.count ?? 0
    }
}

extension CueListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cue = self.activeDocument?.transport.score.cueList[row] else {
            fatalError("No cue list")
        }
        guard
            let id = tableColumn?.identifier,
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: id.rawValue+"Cell"), owner: nil) as? CueColumnCell
        else {
            fatalError("no cell for \(tableColumn)")
        }
        cell.index = row
        cell.fill(from: cue)
        cell.onChange = self.cellChanged
        return cell
        
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}

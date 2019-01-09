//
//  CueListViewController.swift
//  Plink
//
//  Created by acb on 02/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Cocoa

fileprivate let colourCueList = false

class CueListTableView: NSTableView {
    // start editing on click
    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
        return true
    }
}

class CueListHeaderCell: NSTableHeaderCell {
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        if colourCueList {
            NSColor.codeBackground.setFill()
            cellFrame.fill()
        }
        self.drawInterior(withFrame: cellFrame, in: controlView)
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        if colourCueList {
            let titleRect = self.titleRect(forBounds: cellFrame).insetBy(dx: 2, dy: 2)
            self.stringValue.draw(in: titleRect, withAttributes: [ NSAttributedString.Key.foregroundColor: NSColor.lightGray])
        } else {
            super.drawInterior(withFrame: cellFrame, in: controlView)
        }
    }
    
    override func drawFocusRingMask(withFrame cellFrame: NSRect, in controlView: NSView) {
        if !colourCueList {
            super.drawFocusRingMask(withFrame: cellFrame, in: controlView)
        }
    }
    
    override func drawSortIndicator(withFrame cellFrame: NSRect, in controlView: NSView, ascending: Bool, priority: Int) {
        if !colourCueList {
            super.drawSortIndicator(withFrame: cellFrame, in: controlView, ascending: ascending, priority: priority)
        }
    }
    
    override func highlight(_ flag: Bool, withFrame cellFrame: NSRect, in controlView: NSView) {}
}

class CueColumnCell: NSTableCellView {
    var index: Int = 0
    func fill(from cue: ScoreModel.Cue) { }
    var onChange: ((Int, TickTime?, ScoreModel.Cue.Action?)->())?
}

class CueTimeCell: CueColumnCell {
    var time: TickTime = 0
    override func fill(from cue: ScoreModel.Cue) {
        self.textField?.stringValue = TickTimeFormattingService.sharedInstance.format(time: cue.time)
        self.time = cue.time

    }
    
    @IBAction func valueChanged(_ sender: Any) {
        if sender as? NSTextField == self.textField {
            guard let textField = self.textField else { return }
            guard let time = TickTimeFormattingService.sharedInstance.parse(string: textField.stringValue) else {
                print("Badly formatted time: \(self.textField!.stringValue)")
                textField.stringValue = TickTimeFormattingService.sharedInstance.format(time: self.time)
                return
            }
            self.time = time
            self.onChange?(self.index, time, nil)
        }
    }

}

class CueActionCell: CueColumnCell {
    override func fill(from cue: ScoreModel.Cue) {
        switch(cue.action) {
        case .codeStatement(let cs): self.textField?.stringValue = cs
        }
    }
    @IBAction func valueChanged(_ sender: Any) {
        if sender as? NSTextField == self.textField {
            guard let textField = self.textField else { return }
            let action = ScoreModel.Cue.Action.codeStatement(textField.stringValue)
            self.onChange?(self.index, nil, action)
        }
    }
}

extension CueActionCell: NSTextFieldDelegate {
    func controlTextDidBeginEditing(_ obj: Notification) {
        print("beginEditing: \(self.textField!.stringValue)")
    }
    func controlTextDidEndEditing(_ obj: Notification) {
        print("endEditing: \(self.textField!.stringValue)")
    }
}

class CueListViewController: NSViewController {
    @IBOutlet var tableView: NSTableView!
    
    var cueList: [ScoreModel.Cue] = []
    
    override func viewDidLoad() {
        if colourCueList {
            self.tableView.backgroundColor = NSColor.codeBackground
            for col in self.tableView.tableColumns {
                col.headerCell = CueListHeaderCell(textCell: col.headerCell.stringValue)
                col.headerCell.focusRingType = .none
            }
        }
        let doubleClick = NSClickGestureRecognizer(target: self, action: #selector(self.tableDoubleClicked))
        doubleClick.numberOfClicksRequired = 2
        self.tableView.addGestureRecognizer(doubleClick)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        self.cueList = self.activeDocument?.transport.score.cueList ?? []
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
            if newCues == self.cueList { print("Cue list changed but no difference") ; return }
            self.cueList = newCues
            self.tableView.reloadData()
        }
    }
    
    fileprivate func cellChanged(_ index: Int, _ time: TickTime?, _ action: ScoreModel.Cue.Action?) {
        guard let transport = self.activeDocument?.transport else { return }
        let oldCue = self.cueList[index]
        let newCue = ScoreModel.Cue(time: time ?? oldCue.time, action: action ?? oldCue.action)
        self.cueList[index] = newCue
        transport.score.replaceCue(atIndex: index, with: newCue)
    }
    
    @objc func tableDoubleClicked(_ sender: NSClickGestureRecognizer) {
        if self.tableView.row(at: sender.location(in: self.tableView)) == -1 {
            self.addCue()
        }
    }
    
    @IBAction func addPressed(_ sender: Any) {
        self.addCue()
    }
    
    private func addCue() {
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

//
//  CueListViewController.swift
//  Plink
//
//  Created by acb on 02/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Cocoa


class CueListHeaderCell: NSTableHeaderCell {
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        NSColor.codeBackground.setFill()
        cellFrame.fill()
        self.drawInterior(withFrame: cellFrame, in: controlView)
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        let titleRect = self.titleRect(forBounds: cellFrame).insetBy(dx: 2, dy: 2)
        self.stringValue.draw(in: titleRect, withAttributes: [ NSAttributedString.Key.foregroundColor: NSColor.lightGray])
    }
    
    override func drawFocusRingMask(withFrame cellFrame: NSRect, in controlView: NSView) {}
    
    override func drawSortIndicator(withFrame cellFrame: NSRect, in controlView: NSView, ascending: Bool, priority: Int) {}
    
    override func highlight(_ flag: Bool, withFrame cellFrame: NSRect, in controlView: NSView) {}
}

class CueColumnCell: NSTableCellView {
    var index: Int = 0
    var cue: ScoreModel.Cue?
    var onChange: ((Int, ScoreModel.Cue)->())?
}

class CueTimeCell: CueColumnCell {
    override var cue: ScoreModel.Cue? {
        didSet {
            self.textField?.stringValue = (self.cue?.time).map { TickTimeFormattingService.sharedInstance.format(time: $0) } ?? ""
        }
    }
    
    @IBAction func valueChanged(_ sender: Any) {
        if sender as? NSTextField == self.textField {
            guard let textField = self.textField, let cue = self.cue else { return }
            guard let time = TickTimeFormattingService.sharedInstance.parse(string: textField.stringValue) else {
                print("Badly formatted time: \(self.textField!.stringValue)")
                textField.stringValue = TickTimeFormattingService.sharedInstance.format(time: cue.time)
                return
            }
            self.cue = ScoreModel.Cue(time: time, action: cue.action)
            self.onChange?(self.index, self.cue!)
        }
    }

}

class CueActionCell: CueColumnCell {
    override var cue: ScoreModel.Cue? {
        didSet {
            guard let cue = self.cue else { self.textField?.stringValue = "" ; return }
            switch(cue.action) {
            case .codeStatement(let cs): self.textField?.stringValue = cs
            }
            
        }
    }
    @IBAction func valueChanged(_ sender: Any) {
        if sender as? NSTextField == self.textField {
            guard let textField = self.textField, let cue = self.cue else { return }
            self.cue = ScoreModel.Cue(time: cue.time, action: .codeStatement(textField.stringValue))
            self.onChange?(self.index,self.cue!)
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
    
    override func viewDidLoad() {
        self.tableView.backgroundColor = NSColor.codeBackground
        for col in self.tableView.tableColumns {
            col.headerCell = CueListHeaderCell(textCell: col.headerCell.stringValue)
            col.headerCell.focusRingType = .none
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        NotificationCenter.default.addObserver(self, selector: #selector(self.cueListChanged(_:)), name: Transport.cueListChanged, object: nil)
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func cueListChanged(_ notification: Notification) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    fileprivate func cellChanged(_ index: Int, _ cue: ScoreModel.Cue) {
        self.activeDocument?.transport.score.replaceCue(atIndex: index, with: cue)
    }
    
    @IBAction func addPressed(_ sender: Any) {
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
        cell.cue = cue
        cell.onChange = self.cellChanged
        return cell
        
    }
}

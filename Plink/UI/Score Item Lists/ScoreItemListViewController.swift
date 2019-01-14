//
//  ScoreItemListViewController.swift
//  Plink
//
//  Created by acb on 13/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Cocoa

/// The superclass of {Cue,Cycle}ListViewController

fileprivate let colourCueList = true

class ScoreItemListTableView: NSTableView {
    // start editing on click
    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool {
        return true
    }
}

class ColouredTableHeaderCell: NSTableHeaderCell {
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

class ScoreItemListViewController: NSViewController {
    @IBOutlet var tableView: NSTableView!

    override func viewDidLoad() {
        if colourCueList {
            self.tableView.backgroundColor = NSColor.codeBackground
            for col in self.tableView.tableColumns {
                col.headerCell = ColouredTableHeaderCell(textCell: col.headerCell.stringValue)
                col.headerCell.focusRingType = .none
            }
        }
        let doubleClick = NSClickGestureRecognizer(target: self, action: #selector(self.tableDoubleClicked))
        doubleClick.numberOfClicksRequired = 2
        self.tableView.addGestureRecognizer(doubleClick)
    }
    
    @objc func tableDoubleClicked(_ sender: NSClickGestureRecognizer) {
        if self.tableView.row(at: sender.location(in: self.tableView)) == -1 {
            self.addItem()
        }
    }
    
    @IBAction func addPressed(_ sender: Any) {
        self.addItem()
    }
    
    func addItem() {}
}

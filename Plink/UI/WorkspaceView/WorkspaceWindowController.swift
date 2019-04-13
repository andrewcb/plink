//
//  WorkspaceWindowController.swift
//  Plink
//
//  Created by acb on 13/04/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Cocoa

class WorkspaceWindowController: NSWindowController {
    let darkFieldEditor = NSTextView(frame: .zero)
}


extension WorkspaceWindowController: NSWindowDelegate {
    func windowWillReturnFieldEditor(_ sender: NSWindow, to client: Any?) -> Any? {
        if (client as? ScoreItemListTableTextField != nil) {
            self.darkFieldEditor.backgroundColor = .tableFieldEditorBackground
            self.darkFieldEditor.textColor = .tableFieldEditorText
            self.darkFieldEditor.insertionPointColor = .white
            self.darkFieldEditor.selectedTextAttributes = [NSAttributedString.Key.backgroundColor : NSColor.tableFieldEditorSelection]
            return self.darkFieldEditor
        }
        return nil
    }
}

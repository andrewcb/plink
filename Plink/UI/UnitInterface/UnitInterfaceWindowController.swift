//
//  UnitInterfaceWindowController.swift
//  Plink
//
//  Created by acb on 07/05/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Cocoa

class UnitInterfaceWindowController: NSWindowController {
    var audioUnitInstance: ManagedAudioUnitInstance? {
        return (self.contentViewController as? UnitInterfaceViewController)?.audioUnitInstance
    }
}

extension UnitInterfaceWindowController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        self.audioUnitInstance?.interfaceWindow = nil
        self.window = nil
    }
}

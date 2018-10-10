//
//  UnitInterfaceViewController.swift
//  Plink
//
//  Created by acb on 08/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

// a simple protocol to make this compose nicely
protocol ContainsView {
    var containedView: NSView? { get set }
}

/** The parent view controller for the unit interface window */
class UnitInterfaceViewController: NSViewController, ContainsView {
    var containedView: NSView? {
        didSet {
            self.pushContainedView()
        }
    }
    var tabViewController: NSTabViewController?
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let tabController = segue.destinationController as? NSTabViewController {
            self.tabViewController = tabController
        }
    }
    
    private func pushContainedView() {
        for vc in self.tabViewController?.children ?? [] {
            if var cv = vc as? ContainsView {
                cv.containedView = self.containedView
            }
        }
    }
    
}

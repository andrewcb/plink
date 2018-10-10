//
//  UnitGUIViewController.swift
//  Plink
//
//  Created by acb on 08/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

class UnitGUIViewController: NSViewController, ContainsView {
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet var interfaceContainerView: NSView!

    var containedView: NSView? {
        didSet {
            guard let view = self.containedView else {
                self.interfaceContainerView.subviews.forEach { $0.removeFromSuperview() }
                return
            }
            self.interfaceContainerView.frame = view.bounds
            self.interfaceContainerView.addSubview(view)
        }
    }

}

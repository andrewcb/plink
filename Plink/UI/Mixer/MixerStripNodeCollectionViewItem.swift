//
//  MixerStripNodeCollectionViewItem.swift
//  Plink
//
//  Created by acb on 30/08/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

class MixerStripNodeCollectionViewItem: NSCollectionViewItem {
    
    var onChangePressed: ((NSView)->())? = nil
    var onShowWindowPressed: (()->())? = nil

    @IBOutlet var titleLabel: NSTextField!
    
    @IBAction func showWindow(_ sender: Any) {
        self.onShowWindowPressed?()
    }
    
    @IBAction func doChange(_ sender: Any) {
        self.onChangePressed?(self.view)
    }
    
}

//
//  OneButtonCollectionViewItem.swift
//  GDAW01
//
//  Created by acb on 03/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

// A generic collection view item that has one button and a closure which it calls when that button is pressed; use for many purposes

// NOTE: when binding UI elements in NSCollectionViewItem NIBs, bind them to the “File's Owner” (i.e., the relevant instance), not the NSCollectionViewItem Object (which is disembodied and stateless)
class OneButtonCollectionViewItem: NSCollectionViewItem {

    var onPress: ((NSView)->())? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
     
    @IBAction func buttonPressed(_ sender: Any) {
        self.onPress?(self.view)
    }
}

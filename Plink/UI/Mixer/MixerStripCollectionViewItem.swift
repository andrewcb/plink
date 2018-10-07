//
//  MixerStripCollectionViewItem.swift
//  Plink
//
//  Created by acb on 30/08/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

class MixerStripCollectionViewItem: NSCollectionViewItem {
    
    @IBOutlet var nameField: NSTextField!
    @IBOutlet var levelSlider: NSSlider!
    @IBOutlet var panSlider: NSSlider!
    @IBOutlet var nodesCollectionView: NSCollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        ["MixerStripAddNodeCollectionViewItem","MixerStripNodeCollectionViewItem"].forEach { (nib) in
            nodesCollectionView.register(NSNib(nibNamed: nib, bundle: nil), forItemWithIdentifier: NSUserInterfaceItemIdentifier(nib))
        }
    }
    
    public func refresh() {
        self.nodesCollectionView.reloadData()
    }
    
    @IBAction func nameChanged(_ sender: Any) {
    }
    
    @IBAction func levelChanged(_ sender: Any) {
    }
    
    @IBAction func panChanged(_ sender: Any) {
    }
}

extension MixerStripCollectionViewItem: NSCollectionViewDataSource {
    
    enum Section: Int {
        case instrument = 0
        case inserts = 1
    }
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        fatalError("Not implemented yet")
    }
}

extension MixerStripCollectionViewItem: NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return NSSize(width: self.view.bounds.width - 4.0, height: 30.0)
    }
}

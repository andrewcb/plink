//
//  MixerViewController.swift
//  Plink
//
//  Created by acb on 06/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa
import AudioToolbox

class MixerViewController: NSViewController {

    class Layout: NSCollectionViewFlowLayout {
        override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
            return true
        }
    }
    
    @IBOutlet var mixerCollectionView: NSCollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.setupCollectionView()
    }

    private func setupCollectionView() {
        let layout = Layout()
        layout.scrollDirection = .horizontal
        self.mixerCollectionView.collectionViewLayout = layout
        ["MixerStripCollectionViewItem", "MixerAddStripCollectionViewItem"].forEach { (nib) in
            mixerCollectionView.register(NSNib(nibNamed: nib, bundle: nil), forItemWithIdentifier: NSUserInterfaceItemIdentifier(nib))
        }
    }
    
    override func viewDidLayout() {
        self.mixerCollectionView.collectionViewLayout?.invalidateLayout()
    }
}

extension MixerViewController: NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 0
//        return (self.audioSystem?.channels.count ?? 0) + 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        fatalError("Not implemented yet")
    }
}

extension MixerViewController: NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let stripWidth: CGFloat = 128.0
        return NSSize(width: stripWidth, height: collectionView.enclosingScrollView!.bounds.size.height - 2)
    }
}

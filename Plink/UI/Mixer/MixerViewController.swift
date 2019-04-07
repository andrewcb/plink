//
//  MixerViewController.swift
//  Plink
//
//  Created by acb on 06/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa
import AudioToolbox

/// Something that can be told to refresh its displayed value, inexpensively, at a relatively high frequency
protocol RefreshableDisplay {
    func refreshDisplay()
}

class MixerViewController: NSViewController {

    class Layout: NSCollectionViewFlowLayout {
        override func shouldInvalidateLayout(forBoundsChange newBounds: NSRect) -> Bool {
            return true
        }
    }
    
    @IBOutlet var mixerCollectionView: NSCollectionView!
    
    var levelUpdateTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.setupCollectionView()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.mixerCollectionView.reloadData()
        self.levelUpdateTimer = Timer.scheduledTimer(timeInterval: 0.04, target: self, selector: #selector(self.updateLevels), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear() {
        self.levelUpdateTimer?.invalidate()
        self.levelUpdateTimer = nil
        super.viewWillDisappear()
    }
    
    @objc func updateLevels() {
        for item in self.mixerCollectionView.visibleItems() {
            (item as? RefreshableDisplay)?.refreshDisplay()
        }

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
    
    // MARK: opening the component selector
    private var _selectorCompletion: ((AudioUnitComponent)->())?
    private var _selectorTypesNeeded: [OSType] = [kAudioUnitType_MusicDevice]
    private var _popover: NSPopover?
    func openAudioUnitDialog(fromView view: NSView, withTypes types: [OSType], completion:@escaping ((AudioUnitComponent)->())) {
        self._selectorTypesNeeded = types
        self._selectorCompletion = completion
        let popover = NSPopover()
        let vc = self.storyboard!.instantiateController(withIdentifier: "AudioUnitListPopoverViewController") as! AudioUnitListViewController
        vc.typesNeeded = types
        vc.onSelection = { [weak self] (component) in
            self?._popover?.close()
            completion(component)
        }
        popover.contentViewController =  vc as NSViewController
        popover.behavior = .transient
//        popover.delegate = self
        let anchorRect: NSRect = view.superview!.convert(view.frame, to: self.view)
        self._popover = popover
        popover.show(relativeTo: anchorRect, of: self.view, preferredEdge: .maxX)
    }

    
    // MARK: Opening the AudioUnit interface view
    
    private var audioUnitInstanceForGUI: ManagedAudioUnitInstance?
    func openUnitInterface(forNode node: AudioUnitGraph<ManagedAudioUnitInstance>.Node ) {
        do {
            self.audioUnitInstanceForGUI = try node.getInstance()
            self.performSegue(withIdentifier: "OpenUnitInterface", sender: nil)
        } catch {
            
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let windowController = segue.destinationController as? NSWindowController {
            if let uivc = windowController.contentViewController as? UnitInterfaceViewController {
                uivc.audioUnitInstance = self.audioUnitInstanceForGUI
            }
        }
    }
}

extension MixerViewController: NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let audioSystem = self.world?.audioSystem else { return 0 }
        return audioSystem.channels.count + 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let audioSystem = self.world?.audioSystem else { fatalError() /* no audio system == no cells */ }
        guard indexPath[1] < audioSystem.channels.count else {
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MixerAddStripCollectionViewItem"), for: indexPath) as! OneButtonCollectionViewItem
            item.onPress = { [weak self] _ in
                print("Add a channel!")
                do {
                    try audioSystem.createChannel()
                    self?.mixerCollectionView.reloadData()
                } catch {
                    print("Adding channel failed: \(error)")
                }
            }
            return item
            
        }
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MixerStripCollectionViewItem"), for: indexPath)
        guard let collectionViewItem = item as? MixerStripCollectionViewItem
        else {return item}
        let channel = audioSystem.channels[indexPath[1]]
        collectionViewItem.channel = channel
        collectionViewItem.onRequestInstrumentChoice = { (view) in
            self.openAudioUnitDialog(fromView: view, withTypes: [kAudioUnitType_MusicDevice]) { (component) in
                print("Will set instrument for \(channel) to \(component)")
                try! channel.loadInstrument(fromDescription: component.audioComponentDescription)
                collectionViewItem.refresh()
            }
        }
        collectionViewItem.onRequestInsertAdd = { (view) in
            // TODO: allow combinations of types
            self.openAudioUnitDialog(fromView: view, withTypes: [kAudioUnitType_Effect, kAudioUnitType_MusicEffect]) { (component) in
                print("Will add insert for \(channel) to \(component)")
                try! channel.addInsert(fromDescription: component.audioComponentDescription)
                collectionViewItem.refresh()
            }
            
        }
        collectionViewItem.onRequestAUInterfaceWindowOpen = { node in
            self.openUnitInterface(forNode: node)
        }
        collectionViewItem.view.wantsLayer = true
        collectionViewItem.view.layer?.backgroundColor = NSColor.mixerBackground.cgColor
        collectionViewItem.nameField.stringValue = channel.name
        return item
    }
}

extension MixerViewController: NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        let stripWidth: CGFloat = 128.0
        return NSSize(width: stripWidth, height: collectionView.enclosingScrollView!.bounds.size.height - 2)
    }
}

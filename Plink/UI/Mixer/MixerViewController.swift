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
    func openChannelComponentChooser(ofType type: ComponentSelectorViewController.ComponentType, fromView view: NSView, completion:@escaping ((ComponentSelectorViewController.Selection)->())) {
        let viewControllerIdentifier: String
        switch(type) {
        case .instrument: viewControllerIdentifier = "InstrumentSelectorPopoverViewController"
        case .audioEffect: viewControllerIdentifier = "AudioEffectSelectorPopoverViewController"
        }
        let popover = NSPopover()
        let vc = self.storyboard!.instantiateController(withIdentifier: viewControllerIdentifier) as! ComponentSelectorViewController
        vc.componentType = type
        vc.onSelection = { (component) in
            popover.close()
            completion(component)
        }
        popover.contentViewController =  vc as NSViewController
        popover.behavior = .transient
//        popover.delegate = self
        let anchorRect: NSRect = view.superview!.convert(view.frame, to: self.view)
        popover.show(relativeTo: anchorRect, of: self.view, preferredEdge: .maxX)
    }

    fileprivate func load(soundFont sfurl: URL, intoChannel channel: AudioSystem.Channel) throws {
        try channel.loadInstrument(fromDescription: .dlsSynth)
        try channel.instrument?.getInstance().setProperty(withID: kMusicDeviceProperty_SoundBankURL, scope: kAudioUnitScope_Global, element: 0, to: sfurl)
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
            self.openChannelComponentChooser(ofType: .instrument, fromView: view) { (choice) in
                switch(choice) {
                case .component(let component):
//                    print("Will set instrument for \(channel) to \(component)")
                    try! channel.loadInstrument(fromDescription: component.audioComponentDescription)
                    collectionViewItem.refresh()
                case .goToSoundFont:
                    let openpanel = NSOpenPanel()
                    openpanel.allowedFileTypes = ["sf2"]
                    openpanel.beginSheetModal(for: self.view.window!) { [weak self] (response) in
                        guard
                            let self=self,
                            response == .OK,
                            let url = openpanel.url
                        else { return }
                        try! self.load(soundFont: url, intoChannel: channel)
                        collectionViewItem.refresh()
                    }
                }
            }
        }
        
        collectionViewItem.onRequestInsertAdd = { (view) in
            self.openChannelComponentChooser(ofType: .audioEffect, fromView: view) { (choice) in
                switch(choice) {
                case .component(let component):
                    try! channel.addInsert(fromDescription: component.audioComponentDescription)
                    collectionViewItem.refresh()
                case .goToSoundFont:
                    fatalError() // no SoundFonts here
                }
            }
        }
        collectionViewItem.onRequestInsertRemove = { (index) in
            try? channel.removeInsert(atIndex: index)
            collectionViewItem.refresh()
        }
        collectionViewItem.onRequestInstrumentRemove = { () in
            channel.instrument = nil;
            collectionViewItem.refresh()
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

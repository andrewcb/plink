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
        layout.sectionInset = NSEdgeInsets(top: 0.0, left: 16.0, bottom: 0.0, right: 0.0)
        self.mixerCollectionView.collectionViewLayout = layout
        ["MixerStripCollectionViewItem", "MixerAddStripCollectionViewItem"].forEach { (nib) in
            mixerCollectionView.register(NSNib(nibNamed: nib, bundle: nil), forItemWithIdentifier: NSUserInterfaceItemIdentifier(nib))
        }
    }
    
    override func viewDidLayout() {
        self.mixerCollectionView.collectionViewLayout?.invalidateLayout()
    }
    
    // MARK: opening the component selector
    func openChannelComponentChooser(ofType type: ComponentSelectorPopover.ComponentType, fromView view: NSView, completion:@escaping ((ComponentSelectorPopover.Selection)->())) {
        let popover = ComponentSelectorPopover(type: type, fromStoryboard: self.storyboard!, completion: completion)
        let anchorRect: NSRect = view.superview!.convert(view.frame, to: self.view)
        popover.show(relativeTo: anchorRect, of: self.view, preferredEdge: .maxX)
    }

    fileprivate func load(soundFont sfurl: URL, intoChannel channel: AudioSystem.Channel) throws {
        try channel.loadInstrument(fromDescription: .dlsSynth)
        try channel.instrument?.getInstance().setProperty(withID: kMusicDeviceProperty_SoundBankURL, scope: kAudioUnitScope_Global, element: 0, to: sfurl)
    }
    
    // MARK: channel-strip user action request handlers
    // these are curried functions that take context
    fileprivate func requestInstrumentChoiceHandler(forChannel channel: AudioSystem.Channel, collectionViewItem: MixerStripCollectionViewItem) -> ((NSView)->()) {
        return { (view) in
            self.openChannelComponentChooser(ofType: .instrument, fromView: view) { (choice) in
                (try? channel.instrument?.getInstance())??.prepareForRemoval()
                switch(choice) {
                case .component(let component):
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
    }
    
    fileprivate func requestInsertChoiceHander(forChannel channel: AudioSystem.Channel, collectionViewItem: MixerStripCollectionViewItem) -> ((Int, NSView)->()) {
        return { (index, view) in
            self.openChannelComponentChooser(ofType: .audioEffect, fromView: view) { (choice) in
                switch(choice) {
                case .component(let component):
                    if index < channel.inserts.count {
                        (try? channel.inserts[index].getInstance())?.prepareForRemoval()
                    }
                    try! channel.replaceInsert(atIndex: index, usingDescription: component.audioComponentDescription)
                default:
                    fatalError("SoundFonts not available as inserts")
                }
                collectionViewItem.refresh()
            }
        }
    }
    
    fileprivate func requestInsertAdditionHandler(forChannel channel: AudioSystem.Channel, collectionViewItem: MixerStripCollectionViewItem) -> ((NSView)->()) {
        return { (view) in
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
    }

    fileprivate func requestInstrumentRemoveHandler(forChannel channel: AudioSystem.Channel, collectionViewItem: MixerStripCollectionViewItem) -> (()->()) {
        return { () in
            (try? channel.instrument?.getInstance())??.prepareForRemoval()
            channel.instrument = nil;
            collectionViewItem.refresh()
        }
    }
    
    fileprivate func requestInsertRemoveHandler(forChannel channel: AudioSystem.Channel, collectionViewItem: MixerStripCollectionViewItem) -> ((Int)->()) {
        return { (index) in
            if index < channel.inserts.count {
                (try? channel.inserts[index].getInstance())?.prepareForRemoval()
            }
            try? channel.removeInsert(atIndex: index)
            collectionViewItem.refresh()
        }
    }

    
    // MARK: Opening the AudioUnit interface view
    
    private var audioUnitInstanceForGUI: ManagedAudioUnitInstance?
    func openUnitInterface(forNode node: AudioUnitGraph<ManagedAudioUnitInstance>.Node ) {
        do {
            let instance = try node.getInstance()
            if let window = instance.interfaceWindow {
                window.orderFrontRegardless()
            } else {
                self.audioUnitInstanceForGUI = instance
                self.performSegue(withIdentifier: "OpenUnitInterface", sender: nil)

            }
        } catch {
            
        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if let windowController = segue.destinationController as? NSWindowController {
            if let uivc = windowController.contentViewController as? UnitInterfaceViewController {
                uivc.audioUnitInstance = self.audioUnitInstanceForGUI
                self.audioUnitInstanceForGUI?.interfaceWindow = windowController.window
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
        collectionViewItem.onRequestInstrumentChoice = self.requestInstrumentChoiceHandler(forChannel: channel, collectionViewItem: collectionViewItem)
        collectionViewItem.onRequestInsertChoice = self.requestInsertChoiceHander(forChannel: channel, collectionViewItem: collectionViewItem)
        collectionViewItem.onRequestInsertAdd = self.requestInsertAdditionHandler(forChannel: channel, collectionViewItem: collectionViewItem)
        collectionViewItem.onRequestInsertRemove = self.requestInsertRemoveHandler(forChannel: channel, collectionViewItem: collectionViewItem)
        collectionViewItem.onRequestInstrumentRemove = self.requestInstrumentRemoveHandler(forChannel: channel, collectionViewItem: collectionViewItem)
        collectionViewItem.onRequestAUInterfaceWindowOpen = self.openUnitInterface(forNode:)
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

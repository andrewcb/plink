//
//  AudioUnitListViewController.swift
//  Plink
//
//  Created by acb on 05/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa
import AudioToolbox

class AudioUnitListViewController: NSViewController {
    @IBOutlet weak var instrumentsOutlineView: NSOutlineView!
    
    var typesNeeded: [OSType] = [] {
        didSet {
            self.reloadInstruments()
        }
    }
    
    var hasSoundFontItem: Bool = false
    
    enum OutlineItem {
        case manufacturer(Int)
        case component(AudioUnitComponent)
        case soundFontItem
    }
    
    
    // returning a user selection, i.e., a component, or a special choice if available
    enum Selection {
        case component(AudioUnitComponent)
        case goToSoundFont // go to the SoundFont workflow
    }
    var onSelection: ((Selection)->())? = nil
    
    var availableInstruments = [AudioUnitComponent]() {
        didSet {
            print("Setting availableInstruments")
            var d: [String:[AudioUnitComponent]] = [:]
            for inst in self.availableInstruments {
                let manufacturerName = inst.manufacturerName ?? "?"
                var a = d[manufacturerName] ?? []
                a.append(inst)
                d[manufacturerName] = a
            }
            self.instrumentsByManufacturer = d.keys.sorted().map { ($0, d[$0]!.sorted { ($0.componentName ?? "") < ($1.componentName ?? "") })}
        }
    }
    var instrumentsByManufacturer: [(String, [AudioUnitComponent])] = [] {
        didSet {
            print("did set instrumentsByManufacturer: \(self.instrumentsByManufacturer.count) manufacturers")
            DispatchQueue.main.async { [weak self] in
                self?.instrumentsOutlineView.reloadData()
            }
        }
    }

    func component(byDescription description: AudioComponentDescription) -> AudioUnitComponent? {
        return self.availableInstruments.first(where: { $0.audioComponentDescription == description })
    }

    private func reloadInstruments() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let s = self else { return }
            s.availableInstruments = s.typesNeeded.flatMap { tp in AudioUnitComponent.findAll(matching: AudioComponentDescription(componentType: tp, componentSubType: 0, componentManufacturer: 0, componentFlags: 0, componentFlagsMask: 0)) }
//            print("got \(s.availableInstruments.count) instruments")
        }
    }
    
    
    @IBAction func doubleClicked(_ sender: NSOutlineView) {
        guard let item = sender.item(atRow: sender.clickedRow) as? OutlineItem else { return }
        switch(item) {
        case .component(let component):
            self.onSelection?(.component(component))
            self.view.window?.close()
        case .manufacturer(let item):
            if sender.isItemExpanded(item) {
                sender.collapseItem(item)
            } else {
                sender.expandItem(item)
            }
        case .soundFontItem:
            self.onSelection?(.goToSoundFont)
            self.view.window?.close()
        }
    }
}

extension AudioUnitListViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let i2 = item, let item = i2 as? OutlineItem else {
            // top-level
            return self.instrumentsByManufacturer.count + (self.hasSoundFontItem ? 1 : 0)
        }
        switch(item) {
        case .manufacturer(let index): return self.instrumentsByManufacturer[index].1.count
        default: return 0
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let ii = item, let oi = ii as? OutlineItem else {
            let manuIndex = index - (hasSoundFontItem ? 1 : 0 )
            return manuIndex < 0 ? OutlineItem.soundFontItem : OutlineItem.manufacturer(index)
        }
        switch(oi) {
        case .manufacturer(let mi): return OutlineItem.component(self.instrumentsByManufacturer[mi].1[index])
        default: fatalError()
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let oi = item as? OutlineItem, case let .manufacturer(_) = oi { return true }
        else { return false }
    }
}

extension AudioUnitListViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?
        
        guard let oi = item as? OutlineItem else { return nil }
        switch(oi) {
        case .manufacturer(let i):
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ManufacturerCell"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = self.instrumentsByManufacturer[i].0
            }
        case .component(let component):
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ComponentCell"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = component.componentName ?? "-"
            }
        case .soundFontItem:
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ComponentCell"), owner: self) as? NSTableCellView
            view?.textField?.stringValue = "Load a SoundFont"
        }

        return view
    }    
}


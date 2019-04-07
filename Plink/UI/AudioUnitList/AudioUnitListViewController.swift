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
    
    var typesNeeded: [OSType] = [] { //} = kAudioUnitType_MusicDevice {
        didSet {
            self.reloadInstruments()
        }
    }
    
    var onSelection: ((AudioUnitComponent)->())? = nil
    
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
//            s.availableInstruments = s.playbackEngine.getListOfInstruments()
            s.availableInstruments = s.typesNeeded.flatMap { tp in AudioUnitComponent.findAll(matching: AudioComponentDescription(componentType: tp, componentSubType: 0, componentManufacturer: 0, componentFlags: 0, componentFlagsMask: 0)) }
            print("got \(s.availableInstruments.count) instruments")
        }
    }
    
    
    @IBAction func doubleClicked(_ sender: NSOutlineView) {
        guard let item = sender.item(atRow: sender.clickedRow) else { return }
        if let component = item as? AudioUnitComponent {
            // component selected
            self.onSelection?(component)
            self.view.window?.close()
        }
        if item as? Int != nil {
            // top-level index double-clicked; expand/close
            if sender.isItemExpanded(item) {
                sender.collapseItem(item)
            } else {
                sender.expandItem(item)
            }
        }
    }
}

extension AudioUnitListViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let index = item as? Int {
            return self.instrumentsByManufacturer[index].1.count
        } else {
            return self.instrumentsByManufacturer.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let ii = item as? Int {
            return self.instrumentsByManufacturer[ii].1[index]
        } else {
            return index
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return item as? Int != nil
    }
}

extension AudioUnitListViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?
        
        if let i = item as? Int {
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ManufacturerCell"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = self.instrumentsByManufacturer[i].0
            }
        } else if let component = item as? AudioUnitComponent {
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ComponentCell"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = component.componentName ?? "-"
            }
        }
        return view
    }    
}


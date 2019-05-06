//
//  ComponentSelectorPopover.swift
//  Plink
//
//  Created by acb on 06/05/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Cocoa

class ComponentSelectorPopover: NSPopover {
    public enum ComponentType: String {
        case instrument = "Instrument"
        case audioEffect = "AudioEffect"
        
        var viewControllerID: String { return self.rawValue + "SelectorPopoverViewController"}
        
        var osTypes: [OSType] {
            switch self {
            case .instrument: return [kAudioUnitType_MusicDevice]
            case .audioEffect: return [kAudioUnitType_Effect, kAudioUnitType_MusicEffect]
            }
        }
    }
    
    // returning a user selection, i.e., a component, or a special choice if available
    enum Selection {
        case component(AudioUnitComponent)
        case goToSoundFont // go to the SoundFont workflow
    }

    init(type: ComponentType, fromStoryboard storyboard: NSStoryboard, completion:@escaping ((ComponentSelectorPopover.Selection)->())) {
        super.init()
        let vc = storyboard.instantiateController(withIdentifier: type.viewControllerID) as! ComponentSelectorViewController
        vc.componentType = type
        vc.onSelection = { [weak self] (component) in
            self?.close()
            completion(component)
        }
        self.contentViewController =  vc as NSViewController
        self.behavior = .transient
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}


//
//  AudioUnitComponent.swift
//  Plink
//
//  Created by acb on 23/03/2018.
//  Copyright © 2018 acb. All rights reserved.
//

import Foundation
import CoreAudio
import AudioToolbox

public struct AudioUnitComponent {
    let component: AudioComponent
    
    public var manufacturerName: String?
    public var componentName: String?
    public var audioComponentDescription: AudioComponentDescription
    
    public init(component: AudioComponent) {
        self.component = component
        var strPtr: Unmanaged<CFString>?
        AudioComponentCopyName(self.component, &strPtr)
        let components =  (strPtr?.takeRetainedValue() as String?).map { $0.components(separatedBy: ": ") }
        self.manufacturerName = components.flatMap { $0.count >= 2 ? $0[0] : nil }
        self.componentName = components.flatMap { $0.count >= 2 ? $0[1] : $0.first }
        var desc = AudioComponentDescription()
        AudioComponentGetDescription(self.component, &desc)
        self.audioComponentDescription = desc
    }
    
    public static func findAll(matching description: AudioComponentDescription) -> [AudioUnitComponent] {
        var result: [AudioUnitComponent] = []
        var lastFound: AudioComponent? = nil
        var desc = description // needed for the pointer semantics
        var found = AudioComponentFindNext(lastFound, &desc)
        while let f = found {
            result.append(AudioUnitComponent(component: f))
            lastFound = found
            found = AudioComponentFindNext(lastFound, &desc)
        }
        return result
    }
}

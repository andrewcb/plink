//
//  AudioUnitInstanceParameterInfo.swift
//  Plink
//
//  Created by acb on 11/12/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation
import AudioToolbox
import CoreAudio

// A struct to encapsulate the specs of a parameter in a more modern fashion
public struct AudioUnitInstanceParameterInfo {
    public let id: AudioUnitParameterID
    public let name: String?
    public let unit: AudioUnitParameterUnit
    public let range: ClosedRange<AudioUnitParameterValue>
    public let defaultValue: AudioUnitParameterValue
    public let flags: AudioUnitParameterOptions
    
    init(id: AudioUnitParameterID, info: AudioUnitParameterInfo) {
        self.id = id
        self.name = (info.cfNameString?.takeUnretainedValue()).map { $0 as String }
        self.unit = info.unit
        self.range = (info.minValue...info.maxValue)
        self.defaultValue = info.defaultValue
        self.flags = info.flags
    }
}

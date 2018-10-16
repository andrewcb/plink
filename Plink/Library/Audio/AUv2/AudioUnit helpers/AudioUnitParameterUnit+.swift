//
//  AudioUnitParameterUnit+.swift
//  Plink
//
//  Created by acb on 16/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation
import AudioToolbox

extension AudioUnitParameterUnit: CustomStringConvertible {
    public var description: String {
        switch(self) {
            
        case .generic: return "generic"
        case .indexed: return "indexed"
        case .boolean: return "boolean"
        case .percent: return "%"
        case .seconds: return "sec"
        case .sampleFrames: return "frames"
        case .phase: return "phase"
        case .rate: return "rate"
        case .hertz: return "Hz"
        case .cents: return "cents"
        case .relativeSemiTones: return "relativeSemi"
        case .midiNoteNumber: return "midiNote"
        case .midiController: return "midiCtrl"
        case .decibels: return "dB"
        case .linearGain: return "linearGain"
        case .degrees: return "º"
        case .equalPowerCrossfade: return "equalPowerCrossfade"
        case .mixerFaderCurve1: return "mixerFaderCurve1"
        case .pan: return "pan"
        case .meters: return "meters"
        case .absoluteCents: return "absoluteCents"
        case .octaves: return "octaves"
        case .BPM: return "BPM"
        case .beats: return "beats"
        case .milliseconds: return "ms"
        case .ratio: return "ratio"
        case .customUnit: return "custom"
        }
    }
    
    
}

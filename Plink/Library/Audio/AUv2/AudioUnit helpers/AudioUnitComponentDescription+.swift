//
//  AudioUnitComponentDescription+.swift
//  Plink
//
//  Created by acb on 31/08/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation
import CoreAudio
import AudioToolbox

extension AudioComponentDescription {
    
    public init(type: OSType, subType: OSType, manufacturer: OSType) {
        self.init(componentType: type, componentSubType: subType, componentManufacturer: manufacturer, componentFlags: 0, componentFlagsMask: 0)
    }
    
    public static let defaultOutput = AudioComponentDescription(type: kAudioUnitType_Output, subType: kAudioUnitSubType_DefaultOutput, manufacturer: kAudioUnitManufacturer_Apple)
    public static let genericOutput = AudioComponentDescription(type: kAudioUnitType_Output, subType: kAudioUnitSubType_GenericOutput, manufacturer: kAudioUnitManufacturer_Apple)
    public static let stereoMixer = AudioComponentDescription(type: kAudioUnitType_Mixer, subType: kAudioUnitSubType_StereoMixer, manufacturer: kAudioUnitManufacturer_Apple)
    public static let multiChannelMixer = AudioComponentDescription(type: kAudioUnitType_Mixer, subType: kAudioUnitSubType_MultiChannelMixer, manufacturer: kAudioUnitManufacturer_Apple)
    public static let dlsSynth = AudioComponentDescription(type: kAudioUnitType_MusicDevice, subType: kAudioUnitSubType_DLSSynth, manufacturer: kAudioUnitManufacturer_Apple)
}

extension AudioComponentDescription: Equatable {
    // We care only about the (manufacturer, type, subtype) tuple, as the flags field is disused and likely to remain so.
    public static func ==(lhs: AudioComponentDescription, rhs: AudioComponentDescription) -> Bool {
        return lhs.componentType == rhs.componentType && lhs.componentSubType == rhs.componentSubType && lhs.componentManufacturer == rhs.componentManufacturer
    }
}

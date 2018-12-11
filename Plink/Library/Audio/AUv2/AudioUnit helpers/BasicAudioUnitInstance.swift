//
//  AudioUnitInstanceBase.swift
//  Plink
//
//  Created by acb on 07/12/2017.
//  Copyright © 2017 acb. All rights reserved.
//

// A basic no-frills encapsulation of an AudioUnit. Internally, this is weakly typed, and, say, attempting to send MIDI to a non-instrument will probably cause a runtime error, but this is a very thin wrapper.
public struct BasicAudioUnitInstance: AudioUnitInstance {
    public var auRef: AudioUnit
    
    public init(auRef: AudioUnit) {
        self.auRef = auRef
    }
    
}

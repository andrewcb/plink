//
//  AudioBufferConsumer.swift
//  Plink
//
//  Created by acb on 21/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import CoreAudio

protocol AudioBufferConsumer {
    func feed(_ buffers: UnsafeMutableAudioBufferListPointer, _ numFrames: UInt32)
}

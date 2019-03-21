//
//  TrailingSilence.swift
//  Plink
//
//  Created by acb on 20/03/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//
// The detection of trailing silence (below a certain threshold) for AudioBuffers of Float32 values.

import CoreAudio

extension AudioBuffer {
    func trailingSilence(threshold: Float32) -> Int {
        let collection: AudioBuffer.Samples<Float32> = self.samples()
        guard let brk = collection.lastIndex(where: { fabsf($0) >= threshold }) else { return collection.count }
        return (collection.count - 1) - brk
    }
}

extension UnsafeMutableAudioBufferListPointer {
    /// Detect the trailing silence in a list of N single-channel buffers
    func trailingSilence(threshold: Float32) -> Int {
        return self.map { $0.trailingSilence(threshold: threshold) }.min() ?? 0
    }
}

struct TrailingSilenceCounter {
    var count: Int = 0
    let threshold: Float32
    
    mutating func feed(bufferList: UnsafeMutableAudioBufferListPointer) {
        guard !bufferList.isEmpty else { return }
        let sampleCount = bufferList[0].mDataByteSize / 4
        let bufSilence = bufferList.trailingSilence(threshold: self.threshold)
        if bufSilence < sampleCount {
            self.count = bufSilence
        } else {
            self.count += Int(sampleCount)
        }
    }
}

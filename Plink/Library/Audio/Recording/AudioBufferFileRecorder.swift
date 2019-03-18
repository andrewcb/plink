//
//  AudioBufferFileRecorder.swift
//  Plink
//
//  Created by acb on 21/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import CoreAudio

class AudioBufferFileRecorder: AudioBufferConsumer {
    let ref: ExtAudioFileRef
    init(to url: URL, ofType type: AudioFileTypeID, forStreamDescription asbd: AudioStreamBasicDescription) throws {
        let formatFlags: AudioFormatFlags = (type == kAudioFileAIFFType) ? kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsBigEndian : kAudioFormatFlagIsSignedInteger
        var asbdOutput = AudioStreamBasicDescription(
            mSampleRate: asbd.mSampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: formatFlags,
            mBytesPerPacket: 4, mFramesPerPacket: 1, mBytesPerFrame: 4, mChannelsPerFrame: 2, mBitsPerChannel: 16, mReserved: 0)
        
        var maybeAudioFile: ExtAudioFileRef? = nil
        let result = ExtAudioFileCreateWithURL(url as CFURL, type, &asbdOutput, nil, AudioFileFlags.eraseFile.rawValue, &maybeAudioFile)
        guard let audioFile = maybeAudioFile else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(result), userInfo: nil)
        }
        var asbd = asbd
        ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientDataFormat, UInt32(MemoryLayout<AudioStreamBasicDescription>.size), &asbd)
        self.ref = audioFile
    }
    
    func feed(_ buffers: UnsafeMutablePointer<AudioBufferList>, _ numFrames: UInt32) {
//        print(" + recorder.feed(\(buffers), \(numFrames))")
//        print("   buf[:10] = \(UnsafeBufferPointer<Float32>(buffers.pointee.mBuffers).map { $0 }[0..<10])")
        ExtAudioFileWrite(ref, numFrames, buffers)
    }
    
    deinit {
        ExtAudioFileDispose(ref)
    }
}

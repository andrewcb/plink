//
//  AudioBufferExtensions.swift
//  Plink
//
//  Created by acb on 20/03/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//
//  Extensions for AudioBuffer and related classes

import CoreAudio

extension AudioBuffer {
    /// Construct an AudioBuffer given a function and a count
    init<Element>(count: Int, function: ((Int)->(Element))) {
        let buf = UnsafeMutableBufferPointer<Element>.allocate(capacity: count)
        for i in (0..<count) {
            buf[i] = function(i)
        }
        self.init(buf, numberOfChannels: 1)
    }
    
    /// Construct an AudioBuffer from an array of elements
    init<Element>(_ values: [Element]) {
        self.init(count: values.count, function: { values[$0] })
    }
    
    /// Convenience subscript for inspecting values of an AudioBuffer; requires the ability to infer its desired return type
    subscript<T>(index: Int) -> T {
        return UnsafeBufferPointer<T>(self)[index]
    }
    
    // A typed Sequence/Collection adapter
    struct Samples<T>: Sequence, IteratorProtocol, BidirectionalCollection {
        typealias Element = T
        typealias Index = Int
        
        let buffer: AudioBuffer
        var index: Int = 0
        
        mutating func next() -> T? {
            defer { self.index += 1 }
            if index < Int(buffer.mDataByteSize) / MemoryLayout<T>.stride {
                // we need the "as T" or else it may get the type inference wrong
                return buffer[index] as T
            } else {
                return nil
            }
        }
        
        var startIndex: Int { return 0 }
        var endIndex: Int { return Int(buffer.mDataByteSize) / MemoryLayout<Element>.stride }
        
        subscript<T>(index: Int) -> T {
            return UnsafeBufferPointer<T>(buffer)[index]
        }
        
        func index(after i: Int) -> Int {
            return i+1
        }
        
        func index(before i: Int) -> Int {
            return i-1
        }
    }
    
    func samples<T>() -> Samples<T> {
        return Samples(buffer: self, index: 0)
    }
}

extension AudioBufferList {
    /// Utility function to construct an AudioBufferList from AudioBuffers
    static func allocate(with buffers: [AudioBuffer]) -> UnsafeMutableAudioBufferListPointer {
        let result = AudioBufferList.allocate(maximumBuffers: buffers.count)
        for (i,buf) in buffers.enumerated() {
            result[i] = buf
        }
        return result
    }
}

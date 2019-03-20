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
    
    /// Return the index of the last item in the buffer matching a predicate
    func last<T>(thatMatches predicate: (T)->Bool) -> Int? {
        let count = Int(self.mDataByteSize / UInt32(MemoryLayout<T>.stride))
        for i in (0..<count).reversed() {
            if predicate(self[i]) { return i }
        }
        return nil
    }
}

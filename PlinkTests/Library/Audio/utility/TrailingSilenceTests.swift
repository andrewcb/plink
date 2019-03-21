//
//  TrailingSilenceTests.swift
//  PlinkTests
//
//  Created by acb on 20/03/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import XCTest
@testable import Plink

class TrailingSilenceTests: XCTestCase {

    func testAudioBufferTrailingSilence() {
        XCTAssertEqual(AudioBuffer(count: 10, function: {-1+Float32($0%2)*2}).trailingSilence(threshold: 0.5), 0)
        XCTAssertEqual(AudioBuffer([Float32(1.0), 0.5, 0.25, 0.125, 0.0625, 0.03125]).trailingSilence(threshold: 0.1), 2)
        XCTAssertEqual(AudioBuffer([Float32(1.0), 0.5, 0.25, 0.125, 0.0625, 0.03125]).trailingSilence(threshold: 0.01), 0)
        XCTAssertEqual(AudioBuffer([Float32(1.0), 0.5, 0.25, 0.125, 0.0625, 0.03125, -1.0]).trailingSilence(threshold: 0.1), 0)
        XCTAssertEqual(AudioBuffer([Float32]()).trailingSilence(threshold: 0.1), 0)
    }

    func testAudioBufferListTrailingSilence() {

        XCTAssertEqual(AudioBufferList.allocate(with:[
            AudioBuffer([Float32(0.0), 0.0, 0.001, 0.0]),
            AudioBuffer([Float32(0.0), 0.0, 0.0, 0.0])
            ]).trailingSilence(threshold: 0.01), 4)

        
        XCTAssertEqual(AudioBufferList.allocate(with:[
            AudioBuffer([Float32(0.0), 1.0, 0.001, 0.0]),
            AudioBuffer([Float32(0.0), 0.0, -1.0, 0.0])
        ]).trailingSilence(threshold: 0.01), 1)
    }
    
    func testTrailingSilenceCounter() {
        var tsc = TrailingSilenceCounter(count: 0, threshold: 0.01)
        tsc.feed(bufferList: AudioBufferList.allocate(with:[
            AudioBuffer([Float32(0.0), 1.0, 0.001, 0.0]),
            AudioBuffer([Float32(0.0), 0.0, -1.0, 0.0])
        ]))
        XCTAssertEqual(tsc.count, 1)
        tsc.feed(bufferList: AudioBufferList.allocate(with: [
            AudioBuffer(count: 10, function: {_ in Float32(0)}),
            AudioBuffer(count: 10, function: {_ in Float32(0)})
        ]))
        XCTAssertEqual(tsc.count, 11)
        tsc.feed(bufferList: AudioBufferList.allocate(with:[
            AudioBuffer([Float32(0.0), 1.0, 0.0, 0.0]),
            AudioBuffer([Float32(0.0), 0.0, 0.0, 0.0])
        ]))
        XCTAssertEqual(tsc.count, 2)
    }
}

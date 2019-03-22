//
//  AudioSystemTests.swift
//  PlinkTests
//
//  Created by acb on 28/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import XCTest
@testable import Plink

class AudioSystemTests: XCTestCase {

    func testCreate() {
        let s = try! AudioSystem()
        // nodes should be: mixer node and output node
        XCTAssertEqual(try! s.graph.getNodeCount(), 2)
        let mixer = s.mixerNode
        XCTAssertTrue(try! mixer.isConnected(to: s.outNode!))
    }
    
    func testCreateAndDestroyInstrument() {
        let s = try! AudioSystem()
        let ch = try! s.createChannel()
        XCTAssertEqual(try! s.graph.getNodeCount(), 2)
        try! ch.loadInstrument(fromDescription: AudioComponentDescription.init(type: kAudioUnitType_MusicDevice, subType: kAudioUnitSubType_DLSSynth, manufacturer: kAudioUnitManufacturer_Apple))
        XCTAssertEqual(try! s.graph.getNodeCount(), 3)
        XCTAssertTrue(try! ch.headNode!.isConnected(to: s.mixerNode, input: 0))
        ch.instrument = nil
        XCTAssertEqual(try! s.graph.getNodeCount(), 2)
    }
    
    func testCreateInstrumentAndInsert() {
        let s = try! AudioSystem()
        let ch = try! s.createChannel()
        XCTAssertEqual(try! s.graph.getNodeCount(), 2)
        try! ch.loadInstrument(fromDescription: AudioComponentDescription(type: kAudioUnitType_MusicDevice, subType: kAudioUnitSubType_DLSSynth, manufacturer: kAudioUnitManufacturer_Apple))
        try! ch.addInsert(fromDescription: AudioComponentDescription(type: kAudioUnitType_Effect, subType: kAudioUnitSubType_Delay, manufacturer: kAudioUnitManufacturer_Apple))
        XCTAssertEqual(try! s.graph.getNodeCount(), 4)
        XCTAssertEqual(ch.inserts.count, 1)
        XCTAssertEqual(ch.inserts[0], ch.headNode!)
        XCTAssertTrue(try! ch.inserts[0].isConnected(to: s.mixerNode, input: 0))
        XCTAssertTrue(try! ch.instrument!.isConnected(to: ch.inserts[0], input: 0))
    }

    func testCreateMultipleChannelsWithInserts() {
        let s = try! AudioSystem()
        let ch1 = try! s.createChannel()
        XCTAssertEqual(try! s.graph.getNodeCount(), 2)
        try! ch1.loadInstrument(fromDescription: AudioComponentDescription(type: kAudioUnitType_MusicDevice, subType: kAudioUnitSubType_DLSSynth, manufacturer: kAudioUnitManufacturer_Apple))
        try! ch1.addInsert(fromDescription: AudioComponentDescription(type: kAudioUnitType_Effect, subType: kAudioUnitSubType_Delay, manufacturer: kAudioUnitManufacturer_Apple))
        let ch2 = try! s.createChannel()
        try! ch2.loadInstrument(fromDescription: AudioComponentDescription(type: kAudioUnitType_MusicDevice, subType: kAudioUnitSubType_DLSSynth, manufacturer: kAudioUnitManufacturer_Apple))
        XCTAssertEqual(try! s.graph.getNodeCount(), 5)
        XCTAssertEqual(ch1.inserts.count, 1)
        XCTAssertEqual(ch1.inserts[0], ch1.headNode!)
        XCTAssertTrue(try! ch1.inserts[0].isConnected(to: s.mixerNode, input: 0))
        XCTAssertTrue(try! ch1.instrument!.isConnected(to: ch1.inserts[0], input: 0))
        XCTAssertEqual(ch2.instrument!, ch2.headNode!)
        XCTAssertTrue(try! ch2.headNode!.isConnected(to: s.mixerNode, input: 1))
    }
    
    func testClearGraph() {
        let s = try! AudioSystem()
        let ch = try! s.createChannel()
        try! ch.loadInstrument(fromDescription: AudioComponentDescription.init(type: kAudioUnitType_MusicDevice, subType: kAudioUnitSubType_DLSSynth, manufacturer: kAudioUnitManufacturer_Apple))
        XCTAssertEqual(try! s.graph.getNodeCount(), 3)
        XCTAssertEqual(s.channels.count, 1)
        
        try! s.clear()
        s.graph.dump()
        XCTAssertEqual(try! s.graph.getNodeCount(), 2)
        XCTAssertEqual(s.channels.count, 0)
        XCTAssertTrue(try! s.mixerNode.isConnected(to: s.outNode!))

        let ch2 = try! s.createChannel()
        try! ch2.loadInstrument(fromDescription: AudioComponentDescription.init(type: kAudioUnitType_MusicDevice, subType: kAudioUnitSubType_DLSSynth, manufacturer: kAudioUnitManufacturer_Apple))
        XCTAssertEqual(try! s.graph.getNodeCount(), 3)
        XCTAssertEqual(s.channels.count, 1)
        s.graph.dump()
    }

    ///MARK: Recording
    
    class TestConsumer: AudioBufferConsumer {
        var bufCount: Int = 0
        var peaks: [Float32] = []
        
        func feed(_ buffers: UnsafeMutableAudioBufferListPointer, _ numFrames: UInt32) {
            bufCount += 1
            let bufPeaks = buffers.map { $0.samples().reduce(Float32(0)) { (a,b) in max(a, fabsf(b))  } }
            self.peaks.append(bufPeaks.max() ?? 0)
        }
    }

    func testRender() {
        let s = try! AudioSystem()
        let ch = try! s.createChannel()
        try! ch.loadInstrument(fromDescription: AudioComponentDescription.init(type: kAudioUnitType_MusicDevice, subType: kAudioUnitSubType_DLSSynth, manufacturer: kAudioUnitManufacturer_Apple))
        let inst = try! ch.instrument!.getInstance()
        


        let consumer = TestConsumer()
        try! s.record(toConsumer: { () throws -> AudioBufferConsumer in consumer}, running: { (callback) in
            callback()
        })
        XCTAssertEqual(consumer.bufCount, 1)
        XCTAssertEqual(consumer.peaks, [0])
    }
    
    func testRenderWithRunoutToSilence() {
        let s = try! AudioSystem()
        let ch = try! s.createChannel()
        try! ch.loadInstrument(fromDescription: AudioComponentDescription.init(type: kAudioUnitType_MusicDevice, subType: kAudioUnitSubType_DLSSynth, manufacturer: kAudioUnitManufacturer_Apple))
        let inst = try! ch.instrument!.getInstance()
        
        let consumer = TestConsumer()

        try! s.record(toConsumer: { () throws -> AudioBufferConsumer in consumer}, runoutMode: .toSilence(256, 1000), running: { (callback) in
            try! inst.sendMIDIEvent(0x99, 36, 90, atSampleOffset: 0)
            callback()
        })
        XCTAssertGreaterThan(consumer.bufCount, 1)
        XCTAssertLessThan(consumer.bufCount, 302)
        XCTAssertGreaterThan(consumer.bufCount, 250)
//        XCTAssertEqual(consumer.bufCount, 1)
//        XCTAssertNotEqual(consumer.peaks, [0])
    }
    
    func testRecordToFile() {
        let s = try! AudioSystem()
        
        let outputName = "/tmp/testRecordToFile-\(Int.random(in: (0...999)))"
        try! s.record(to: outputName, running: { (callback) in
            callback()
        })
        let contents = FileManager.default.contents(atPath: outputName)
        XCTAssertNotNil(contents)
        XCTAssert(contents!.count >= 512)
    }

}

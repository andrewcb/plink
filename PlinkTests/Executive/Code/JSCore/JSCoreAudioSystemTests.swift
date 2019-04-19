//
//  JSCoreAudioSystemTests.swift
//  PlinkTests
//
//  Created by acb on 19/04/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import XCTest
@testable import Plink

class JSCoreAudioSystemTests: XCTestCase {

    private func createEnv(hasInstrument: Bool, hasInsertEffect: Bool = false) throws -> CodeEngineEnvironment {
        let s = try! AudioSystem()
        let ch = try! s.createChannel()
        ch.name = "test"
        if hasInstrument {
            try ch.loadInstrument(fromDescription: AudioComponentDescription(type: kAudioUnitType_MusicDevice, subType: kAudioUnitSubType_DLSSynth, manufacturer: kAudioUnitManufacturer_Apple))
        }
        if hasInsertEffect {
            try ch.addInsert(fromDescription: AudioComponentDescription(type: kAudioUnitType_Effect, subType: kAudioUnitSubType_LowPassFilter, manufacturer: kAudioUnitManufacturer_Apple))
        }
        let metro = Metronome()
        return CodeEngineEnvironment(audioSystem: s, metronome: metro, transport: Transport(metronome: metro), scheduler: Scheduler())
    }

    func testGetChannelByName() {
        let engine = JSCoreCodeEngine(env: try! self.createEnv(hasInstrument: false))
        
        let ch1 = (engine.ctx.evaluateScript("$ch.test")!.toObject()) as? JSCoreCodeEngine.Channel
        XCTAssertNotNil(ch1)
        XCTAssertEqual(ch1!.channel.name, "test")
    }

    func testGetChannelInstrumentAbsent() {
        let engine = JSCoreCodeEngine(env: try!  self.createEnv(hasInstrument: false))
        
        let jsv = engine.ctx.evaluateScript("$ch.test.instrument")
        XCTAssertTrue(jsv!.isUndefined)
    }
    
    func testGetChannelInstrumentPresent() {
        let engine = JSCoreCodeEngine(env: try!  self.createEnv(hasInstrument: true))
        
        let jsv = engine.ctx.evaluateScript("$ch.test.instrument")!.toObject()
        let inst = jsv as? JSCoreCodeEngine.Unit
        XCTAssertNotNil(inst)
        XCTAssertEqual(inst!.instance.getAudioUnitComponent()!.audioComponentDescription, AudioComponentDescription(type: kAudioUnitType_MusicDevice, subType: kAudioUnitSubType_DLSSynth, manufacturer: kAudioUnitManufacturer_Apple))
    }

    func testGetChannelEffectEmpty() {
        let engine = JSCoreCodeEngine(env: try!  self.createEnv(hasInstrument: true, hasInsertEffect: false))
        
        let jsv = engine.ctx.evaluateScript("$ch.test.audioEffects")!.toObject()
        let inserts = jsv as? [JSCoreCodeEngine.Unit]
        XCTAssertNotNil(inserts)
        XCTAssertEqual(inserts!.count, 0)
    }
    
    func testGetChannelEffectPresent() {
        let engine = JSCoreCodeEngine(env: try!  self.createEnv(hasInstrument: true, hasInsertEffect: true))
        
        let jsv = engine.ctx.evaluateScript("$ch.test.audioEffects")!.toObject()
        let inserts = jsv as? [JSCoreCodeEngine.Unit]
        XCTAssertNotNil(inserts)
        XCTAssertEqual(inserts!.count, 1)
        XCTAssertEqual(inserts![0].instance.getAudioUnitComponent()!.audioComponentDescription, AudioComponentDescription(type: kAudioUnitType_Effect, subType: kAudioUnitSubType_LowPassFilter, manufacturer: kAudioUnitManufacturer_Apple))
    }
}

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

    private func createEnv(hasInstrument: Bool) throws -> CodeEngineEnvironment {
        let s = try! AudioSystem()
        let ch = try! s.createChannel()
        ch.name = "test"
        if hasInstrument {
            try ch.loadInstrument(fromDescription: AudioComponentDescription(type: kAudioUnitType_MusicDevice, subType: kAudioUnitSubType_DLSSynth, manufacturer: kAudioUnitManufacturer_Apple))
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

    func testGetChannelInstrumentPresent() {
        let engine = JSCoreCodeEngine(env: try!  self.createEnv(hasInstrument: true))
        
        let jsv = engine.ctx.evaluateScript("$ch.test.instrument")!.toObject()
        let inst = jsv as? JSCoreCodeEngine.Unit
        XCTAssertNotNil(inst)
        XCTAssertEqual(inst!.instance.getAudioUnitComponent()!.audioComponentDescription, AudioComponentDescription(type: kAudioUnitType_MusicDevice, subType: kAudioUnitSubType_DLSSynth, manufacturer: kAudioUnitManufacturer_Apple))
    }
}

//
//  JSCoreCodeEngineTests.swift
//  PlinkTests
//
//  Created by acb on 2019-07-21.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import XCTest
@testable import Plink

class JSCoreCodeEngineTests: XCTestCase {
    
    private func createEnv() throws -> CodeEngineEnvironment {
        let s = try! AudioSystem()
        let metro = Metronome()
        return CodeEngineEnvironment(audioSystem: s, metronome: metro, transport: Transport(metronome: metro), scheduler: Scheduler())
    }
    
    func testEvalCommand() {
        let engine = JSCoreCodeEngine(env: try! self.createEnv())
        XCTAssertEqual(engine.eval(command: "2+3"), "5")
    }

    func testSetCodeValueConvertibleInt() {
        let engine = JSCoreCodeEngine(env: try! self.createEnv())
        engine.set(variableNamed: "blah", to: 23)
        XCTAssertEqual(engine.eval(command: "blah+4"), "27")
    }

}

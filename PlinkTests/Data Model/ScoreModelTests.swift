//
//  ScoreModelTests.swift
//  PlinkTests
//
//  Created by acb on 12/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import XCTest
@testable import Plink

class ScoreModelTests: XCTestCase {

    func testDecodeCue() {
        // this is done using JSON, for simplicity; a Cue does not contain embedded binary data, and will serialise identically to plists and JSON
        let data = "{\"time\":57, \"code\":\"playFanfare()\"}".data(using: .utf8)!
        let decoder = JSONDecoder()
        let cue = try! decoder.decode(ScoreModel.Cue.self, from: data)
        XCTAssertEqual(cue.time, TickTime(57))
        XCTAssertEqual(cue.action, ScoreModel.CuedAction.codeStatement("playFanfare()"))
    }
    
    func testDecodeCycle() {
        let data1 = "{\"name\":\"BD\", \"isActive\": false, \"period\":24, \"code\":\"playKick()\"}".data(using: .utf8)!
        let data2 = "{\"name\":\"SD\", \"isActive\": true, \"period\":24, \"modulus\":12, \"code\":\"playSnare()\"}".data(using: .utf8)!
        let decoder = JSONDecoder()
        let cycle1 = try! decoder.decode(ScoreModel.Cycle.self, from: data1)
        XCTAssertEqual(cycle1.name, "BD")
        XCTAssertFalse(cycle1.isActive)
        XCTAssertEqual(cycle1.period, 24)
        XCTAssertEqual(cycle1.modulus, 0)
        XCTAssertEqual(cycle1.action, ScoreModel.CuedAction.codeStatement("playKick()"))
        let cycle2 = try! decoder.decode(ScoreModel.Cycle.self, from: data2)
        XCTAssertEqual(cycle2.name, "SD")
        XCTAssertTrue(cycle2.isActive)
        XCTAssertEqual(cycle2.period, 24)
        XCTAssertEqual(cycle2.modulus, 12)
        XCTAssertEqual(cycle2.action, ScoreModel.CuedAction.codeStatement("playSnare()"))

    }
    
    func testEncodeCue() {
        let cue = ScoreModel.Cue(time: TickTime(23), action: .codeStatement("bang()"))
        let dict = try! JSONSerialization.jsonObject(with: try! JSONEncoder().encode(cue), options: []) as! [String:Any]
        XCTAssertEqual(dict["time"] as! Int, 23)
        XCTAssertEqual(dict["code"] as! String, "bang()")
    }
    
    func testEncodeCycle() {
        let cycle = ScoreModel.Cycle(name: "Nigel", isActive: true, period: 24, modulus: 6, action: .codeStatement("meow()"))
        let dict = try! JSONSerialization.jsonObject(with: try! JSONEncoder().encode(cycle), options: []) as! [String:Any]
        XCTAssertEqual(dict["name"] as! String, "Nigel")
        XCTAssertEqual(dict["isActive"] as! Bool, true)
        XCTAssertEqual(dict["period"] as! Int, 24)
        XCTAssertEqual(dict["modulus"] as! Int, 6)
        XCTAssertEqual(dict["code"] as! String, "meow()")
    }

}

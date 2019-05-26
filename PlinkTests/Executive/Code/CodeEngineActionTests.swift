//
//  CodeEngineActionTests.swift
//  PlinkTests
//
//  Created by acb on 2019-05-26.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import XCTest
@testable import Plink

class CodeEngineActionTests: XCTestCase {

    func testCreateFromCodeText() {
        XCTAssertEqual(CodeEngineAction(codeText: "anIdentifier"), .callProcedure("anIdentifier"))
        XCTAssertEqual(CodeEngineAction(codeText: "another_id"), .callProcedure("another_id"))
        XCTAssertEqual(CodeEngineAction(codeText: "_another_id123"), .callProcedure("_another_id123"))
        XCTAssertEqual(CodeEngineAction(codeText: "eliminateWhiteSpace "), .callProcedure("eliminateWhiteSpace"))
        XCTAssertEqual(CodeEngineAction(codeText: "$foo"), .callProcedure("$foo"))
        XCTAssertEqual(CodeEngineAction(codeText: "doSomething(1,2,3)"), .codeStatement("doSomething(1,2,3)"))
        XCTAssertEqual(CodeEngineAction(codeText: " doSomething(1,2,3) "), .codeStatement("doSomething(1,2,3)"))
    }

}

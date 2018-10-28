//
//  NSRect+ComposableTests.swift
//  PlinkTests
//
//  Created by acb on 27/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import XCTest
@testable import Plink

class NSRect_ComposableTests: XCTestCase {


    func testSliceHorizontally() {
        let slices = NSRect(x: 5, y: 2, width: 100, height: 100).sliceHorizontally(intoPieces: 10)
        XCTAssertEqual(slices[0], NSRect(x: 5, y: 2, width: 10, height: 100))
        XCTAssertEqual(slices[1], NSRect(x: 15, y: 2, width: 10, height: 100))
        XCTAssertEqual(slices[2], NSRect(x: 25, y: 2, width: 10, height: 100))
    }

    func testSliceVertically() {
        let slices = NSRect(x: 0, y: 0, width: 100, height: 100).sliceVertically(intoPieces: 5)
        XCTAssertEqual(slices[0], NSRect(x: 0, y: 0, width: 100, height: 20))
        XCTAssertEqual(slices[1], NSRect(x: 0, y: 20, width: 100, height: 20))
        XCTAssertEqual(slices[2], NSRect(x: 0, y: 40, width: 100, height: 20))
    }
    
    func testScaled() {
        XCTAssertEqual(NSRect(x: 10, y: 20, width: 100, height: 20).scaled(x:0.5), NSRect(x: 10, y: 20, width: 50, height: 20))
    }
}

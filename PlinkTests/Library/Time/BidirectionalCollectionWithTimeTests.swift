//
//  BidirectionalCollectionWithTimeTests.swift
//  PlinkTests
//
//  Created by acb on 05/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import XCTest
@testable import Plink

class BidirectionalCollectionWithTimeTests: XCTestCase {

    func testExample() {
        let seq: [TimedBox<Int>] = [
            TimedBox(time: 10, value: 10),
            TimedBox(time: 10, value: 11),
            TimedBox(time: 11, value: 10),
            TimedBox(time: 12, value: 7),
            TimedBox(time: 15, value: 1),
            TimedBox(time: 17, value: 4)
        ]
        
        XCTAssertEqual(seq.index(bySeekingFrom: 2, toStartOfElementsNotBefore: 10), 0)
        XCTAssertEqual(seq.index(bySeekingFrom: 0, toStartOfElementsNotBefore: 10), 0)
        XCTAssertEqual(seq.index(bySeekingFrom: 1, toStartOfElementsNotBefore: 10), 0)
        XCTAssertEqual(seq.index(bySeekingFrom: seq.endIndex, toStartOfElementsNotBefore: 10), 0)
        XCTAssertEqual(seq.index(bySeekingFrom: seq.endIndex+10, toStartOfElementsNotBefore: 10), 0)
        XCTAssertEqual(seq.index(bySeekingFrom: 2, toStartOfElementsNotBefore: 12), 3)
        XCTAssertEqual(seq.index(bySeekingFrom: 2, toStartOfElementsNotBefore: 17), 5)
        XCTAssertEqual(seq.index(bySeekingFrom: 2, toStartOfElementsNotBefore: 999), seq.endIndex)
    }

}

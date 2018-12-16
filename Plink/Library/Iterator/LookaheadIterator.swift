//
//  LookaheadIterator.swift
//  Plink
//
//  Created by acb on 03/08/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

protocol LookaheadIteratorProtocol: IteratorProtocol {
    var peek: Element? { get }
}

public struct LookaheadIterator<I: IteratorProtocol>: LookaheadIteratorProtocol  {
    //    associatedtype Element = T
    public typealias Element = I.Element
    var iterator: I
    var nextItem: Element?
    
    public init(iterator: I) {
        self.iterator = iterator
        self.nextItem = self.iterator.next()
    }
    
    public init<S: Sequence>(sequence: S) where S.Iterator == I {
        self.iterator = sequence.makeIterator()
        self.nextItem = self.iterator.next()
    }

    public var peek: Element? { return self.nextItem }

    mutating public func next() -> I.Element? {
        let result = self.nextItem
        if result != nil {
            self.nextItem = iterator.next()
        }
        return result
    }
}

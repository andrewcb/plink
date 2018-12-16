//
//  Merge2.swift
//  Plink
//
//  Created by acb on 03/08/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

public struct Merge2Iterator<I: IteratorProtocol>: Sequence, IteratorProtocol {
    public typealias Element = I.Element
    public typealias Comparator = ((I.Element, I.Element) -> Bool)
    var _left: LookaheadIterator<I>?
    var _right: LookaheadIterator<I>?
    public var left: I? {
        didSet {
            self._left = self.left.map { LookaheadIterator(iterator: $0) }
        }
    }
    public var right: I? {
        didSet {
            self._right = self.right.map { LookaheadIterator(iterator: $0) }
        }
    }
    var comparator: Comparator // analogous to <
    
    public init(left: I? = nil, right: I? = nil, comparator: @escaping Comparator) {
        self.left = left
        self.right = right
        self._left = left.map { LookaheadIterator(iterator: $0) }
        self._right = right.map { LookaheadIterator(iterator: $0) }
        self.comparator = comparator
    }
    
    public init<S: Sequence>(left: S? = nil, right: S? = nil, comparator: @escaping Comparator) where S.Iterator == I {
        self.init(left: left.map { $0.makeIterator()}, right: right.map { $0 .makeIterator()}, comparator: comparator)
    }
    
    public mutating func next() -> I.Element? {
        guard let a = _left?.peek else { return _right?.next() }
        guard let b = _right?.peek else { return _left?.next() }
        return self.comparator(a,b) ? _left?.next() : _right?.next()
    }
}

extension Merge2Iterator: LookaheadIteratorProtocol {
    public var peek: I.Element? {
        guard let a = _left?.peek else { return _right?.peek }
        guard let b = _right?.peek else { return _left?.peek }
        return self.comparator(a,b) ? a : b
    }
}

/// Provide a default comparator for sequences of `Comparable`s
extension Merge2Iterator where I.Element: Comparable {
    public init(left: I?, right: I?) {
        self.init(left: left, right: right, comparator: (<))
    }
    
    public init<S: Sequence>(left: S?, right: S?) where S.Iterator == I {
        self.init(left: left, right: right, comparator: (<))
    }
}

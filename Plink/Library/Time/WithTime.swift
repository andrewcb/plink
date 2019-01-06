//
//  WithTime.swift
//  Plink
//
//  Created by acb on 01/08/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

/// Anything that has a TickTime
public protocol WithTime: Comparable {
    var time: TickTime { get }
}


// a point event with a time
public struct TimedBox<T>: WithTime {
    public typealias Value = T
    public let time: TickTime
    public let value: T
    
    public init(time: TickTime, value: T) {
        self.time = time
        self.value = value
    }
}

// this doesn't appear to be legal
//extension TimedBox: Equatable where TimedBox.Value: Equatable {
//    public static func ==(lhs: TimedBox, rhs: TimedBox) -> Bool {
//        return lhs.time == rhs.time && lhs.value == rhs.value
//    }
//}

public extension WithTime {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.time == rhs.time
    }
    static func <(lhs: Self, rhs: Self) -> Bool {
        return lhs.time < rhs.time
    }
}


extension TimedBox: CustomStringConvertible where TimedBox.Value: CustomStringConvertible {
    public var description: String {
        return "{\(self.time): \(self.value.description)}"
    }
}

extension TimedBox: CustomDebugStringConvertible where TimedBox.Value: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "{\(self.time): \(self.value.debugDescription)}"
    }
}

// MARK: Functor

extension TimedBox {
    public func map<U>(transform: ((T)->(U))) -> TimedBox<U> {
        return TimedBox<U>(time: self.time, value: transform(self.value))
    }
}

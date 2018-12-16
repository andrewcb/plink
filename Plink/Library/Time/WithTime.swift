//
//  WithTime.swift
//  Plink
//
//  Created by acb on 01/08/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

public protocol WithTime: Comparable {
    associatedtype Value
    var time: TickTime { get }
    var value: Value { get }
}


// a point event with a time
public struct ItemWithTime<T>: WithTime {
    public typealias Value = T
    public let time: TickTime
    public let value: T
    
    public init(time: TickTime, value: T) {
        self.time = time
        self.value = value
    }
}

// this doesn't appear to be legal
//extension ItemWithTime: Equatable where ItemWithTime.Value: Equatable {
//    public static func ==(lhs: ItemWithTime, rhs: ItemWithTime) -> Bool {
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


extension ItemWithTime: CustomStringConvertible where ItemWithTime.Value: CustomStringConvertible {
    public var description: String {
        return "{\(self.time): \(self.value.description)}"
    }
}

extension ItemWithTime: CustomDebugStringConvertible where ItemWithTime.Value: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "{\(self.time): \(self.value.debugDescription)}"
    }
}

// MARK: Functor

extension WithTime {
    public func map<U>(transform: ((Value)->(U))) -> ItemWithTime<U> {
        return ItemWithTime<U>(time: self.time, value: transform(self.value))
    }
}

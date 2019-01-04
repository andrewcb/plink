import Foundation

/**
 The fundamental unit of MIDI/sequencer-rate time, the tick.
 */
public struct TickTime {
    public static let ticksPerBeat = 24 // change later
    public let value: Int
    
    public var tickValue: Int { return value % TickTime.ticksPerBeat }
    public var beatValue: Int { return value / TickTime.ticksPerBeat }
    
    public init(_ value: Int) { self.value =  value }
    
    public init(beats: Int, ticks: Int) {
        self.value = beats * TickTime.ticksPerBeat + ticks
    }

    static public func +(lhs: TickTime, rhs: TickOffset) -> TickTime {
        return TickTime(lhs.value + rhs.value)
    }
    
    static public func -(lhs: TickTime, rhs: TickOffset) -> TickTime {
        return TickTime(lhs.value - rhs.value)
    }
    
    static public func +=(v: inout TickTime, inc: TickOffset) {
        v = TickTime(v.value+inc.value)
    }
    
    static public func -=(v: inout TickTime, inc: TickOffset) {
        v = TickTime(v.value-inc.value)
    }

    // TODO: split this out if TickDuration is ever separated from TickTime
    static public func *(lhs: TickTime, rhs: Int) -> TickTime {
        return TickTime(lhs.value * rhs)
    }
}

extension TickTime : Equatable {
    public static func ==(lhs: TickTime, rhs: TickTime) -> Bool {
        return lhs.value == rhs.value
    }
    
}

extension TickTime: Comparable {
    public static func < (lhs: TickTime, rhs: TickTime) -> Bool {
        return lhs.value < rhs.value
    }
}

extension TickTime: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.value = Int(value)
    }
}

extension TickTime: CustomStringConvertible {
    public var description: String {
        return "\(self.beatValue)∙\(self.tickValue)"
    }
}

extension TickTime: Hashable {}

public typealias TickDuration = TickTime // it'll do for now
public typealias TickOffset = TickTime // it'll do for now

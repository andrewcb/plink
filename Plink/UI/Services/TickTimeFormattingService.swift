//
//  TickTimeFormattingService.swift
//  Plink
//
//  Created by acb on 03/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Foundation

/// A service for parsing and formatting TickTimes, in a configurable fashion

struct TickTimeFormattingService {
    static var sharedInstance = TickTimeFormattingService()
    
    enum Mode {
        /// display only the total number of ticks
        case ticksOnly
        /// display total beats and ticks
        case beatsAndTicks
        /// display bars, beats and ticks, for an arbitrary number of beats per bar
        case barsBeatsAndTicks(Int)
    }
    /// the current mode
    var mode: Mode = .ticksOnly
    
    /// format a TickTime
    func format(time: TickTime) -> String {
        return self.mode.format(time:time)
    }
    
    func parse(string: String) -> TickTime? {
        return self.mode.parse(string: string)
    }
}

extension TickTimeFormattingService.Mode {
    func format(time: TickTime) -> String {
        switch(self) {
        case .ticksOnly: return "\(time.value)"
        case .beatsAndTicks: return "\(time.beatValue):\(time.tickValue)"
        case .barsBeatsAndTicks(let beatsPerBar):
            let bars = time.beatValue / beatsPerBar
            let beats = time.beatValue % beatsPerBar
            return "\(bars):\(beats):\(time.tickValue)"
        }
    }
    
    private func splitInts(string: String) -> [Int] {
        return string.split(separator: ":").compactMap { Int($0) }
    }
    
    func parse(string: String) -> TickTime? {
        switch(self) {
        case .ticksOnly: return Int(string).map { TickTime($0) }
        case .beatsAndTicks:
            let split = splitInts(string: string)
            if split.count == 0 { return nil }
            let beats = split[0]
            let ticks = split.count>1 ? split[1] : 0
            return TickTime(beats: beats, ticks: ticks)
        case .barsBeatsAndTicks(let bpb):
            let split = splitInts(string: string)
            if split.count == 0 { return nil }
            let bars = split[0]
            let beats = split.count>1 ? split[1] : 0
            let ticks = split.count>2 ? split[2] : 0
            return TickTime(beats: bars*bpb+beats, ticks: ticks)
        }
    }
}

//
//  ScoreModel.swift
//  Plink
//
//  Created by acb on 02/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Foundation

/** The model encapsulating the Score, i.e., all events (not defined in code) mapped to a transport time. */
struct ScoreModel {
    // MARK: a Cue: is a timestamped action (typically code statements to execute)
    struct Cue: WithTime {
        let time: TickTime
        let action: CodeEngineAction
    }
    
    // MARK: a Cycle is a (switchable) periodic action
    struct Cycle {
        let name: String
        var isActive: Bool
        let period: TickDuration
        let modulus: TickTime
        let action: CodeEngineAction
    }
    
    typealias CueList = [Cue]
    
    // MARK: data
    
    /// The base tempo; this is set on start of playback/rendering (though may be mutated through user or code actions)
    public var baseTempo: Double
    
    // A sorted list of Cues, to be executed as the Score plays
    public private(set) var cueList: [Cue]
    
    public private(set) var cycleList: [Cycle]
    
    var onCueListChanged: (()->())? = nil
    var onCycleListChanged: (()->())? = nil
    
    init(baseTempo: Double = 120.0, cueList: [Cue] = [], cycles: [Cycle] = []) {
        self.baseTempo = baseTempo
        self.cueList = cueList
        self.cycleList = cycles
    }
    
    mutating func replaceCue(atIndex index: Int, with cue: Cue) {
        var cues = self.cueList
        cues[index] = cue
        cueList = cues.sorted(by: { (c1, c2) -> Bool in
            c1.time < c2.time
        })
        self.onCueListChanged?()
    }
    
    mutating func add(cue: Cue) {
        self.cueList = (self.cueList + [cue]).sorted(by: { (c1, c2) -> Bool in
            c1.time < c2.time
        })
        self.onCueListChanged?()
    }
    
    mutating func deleteCue(at index: Int) {
        self.cueList.remove(at: index)
        self.onCueListChanged?()
    }
    
    mutating func replaceCycle(atIndex index: Int, with cycle: Cycle) {
        self.cycleList[index] = cycle
        self.onCycleListChanged?()
    }
    
    mutating func add(cycle: Cycle) {
        self.cycleList.append(cycle)
        self.onCycleListChanged?()
    }

    mutating func moveCycle(at srcIndex: Int, to destIndex: Int) {
        let temp = self.cycleList[destIndex]
        self.cycleList[destIndex] = self.cycleList[srcIndex]
        self.cycleList[srcIndex] = temp
        self.onCycleListChanged?()
    }

}

extension ScoreModel.Cue: Equatable {}
extension ScoreModel.Cycle: Equatable {}

extension ScoreModel.Cue: Codable {
    enum CodingKeys: String, CodingKey {
        case time
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.time = TickTime(try container.decode(Int.self, forKey: .time))
        self.action = try CodeEngineAction(from: decoder)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.time.value, forKey: .time)
        try self.action.encode(to: encoder)
    }
}

extension ScoreModel.Cycle: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case isActive
        case period
        case modulus
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
        self.period = TickTime(try container.decode(Int.self, forKey: .period))
        self.modulus = TickTime(try container.decodeIfPresent(Int.self, forKey: .modulus) ?? 0)
        self.action = try CodeEngineAction(from: decoder)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.period.value, forKey: .period)
        if self.modulus.value != 0 { try container.encode(self.modulus.value, forKey: .modulus) }
        try self.action.encode(to: encoder)
    }
}

extension ScoreModel: Codable {
    enum CodingKeys: String, CodingKey {
        case cueList
        case cycles
        case baseTempo
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cueList = try container.decode([Cue].self, forKey: .cueList)
        self.cycleList = try container.decodeIfPresent([Cycle].self, forKey: CodingKeys.cycles) ?? []
        self.baseTempo = try container.decodeIfPresent(Double.self, forKey: CodingKeys.baseTempo) ?? 120.0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.cueList, forKey: .cueList)
        try container.encode(self.cycleList, forKey: .cycles)
        try container.encode(self.baseTempo, forKey: .baseTempo)
    }
}

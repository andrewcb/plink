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
    // A type of action that may be triggered once-off or repeatedly
    enum CuedAction {
        case codeStatement(String)
    }

    // MARK: a Cue: is a timestamped action (typically code statements to execute)
    struct Cue: WithTime {
        let time: TickTime
        let action: CuedAction
    }
    
    // MARK: a Cycle is a (switchable) periodic action
    struct Cycle {
        let name: String
        var isActive: Bool
        let period: TickDuration
        let modulus: TickTime
        let action: CuedAction
    }
    
    // A sorted list of Cues, to be executed as the Score plays
    typealias CueList = [Cue]
    public private(set) var cueList: [Cue]
    
    public private(set) var cycles: [String:Cycle]
    
    var onCueListChanged: (()->())? = nil
    var onCyclesChanged: (()->())? = nil

    init(cueList: [Cue] = [], cycles: [Cycle] = []) {
        self.cueList = cueList
        self.cycles = [String:Cycle](cycles.map { ($0.name, $0) }, uniquingKeysWith: { (a, b) in b })
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
}

extension ScoreModel.CuedAction: Equatable {}
extension ScoreModel.Cue: Equatable {}
extension ScoreModel.Cycle: Equatable {}

extension ScoreModel.Cue: Codable {
    enum CodingKeys: String, CodingKey {
        case time
        case code
    }
    
    struct DecodingError: Swift.Error { }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.time = TickTime(try container.decode(Int.self, forKey: .time))
        if let code = try container.decodeIfPresent(String.self, forKey: .code) {
            self.action = .codeStatement(code)
        } else {
            throw DecodingError()
        }

    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.time.value, forKey: .time)
        switch(self.action) {
        case .codeStatement(let code): try container.encode(code, forKey: .code)
        }
    }
}

extension ScoreModel.Cycle: Codable {
    enum CodingKeys: String, CodingKey {
        case name
        case isActive
        case period
        case modulus
        case code
    }
    struct DecodingError: Swift.Error { }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.isActive = try container.decode(Bool.self, forKey: .isActive)
        self.period = TickTime(try container.decode(Int.self, forKey: .period))
        self.modulus = TickTime(try container.decodeIfPresent(Int.self, forKey: .modulus) ?? 0)
        if let code = try container.decodeIfPresent(String.self, forKey: .code) {
            self.action = .codeStatement(code)
        } else {
            throw DecodingError()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.period.value, forKey: .period)
        if self.modulus.value != 0 { try container.encode(self.modulus.value, forKey: .modulus) }
        switch(self.action) {
        case .codeStatement(let code): try container.encode(code, forKey: .code)
        }

    }
    
}

extension ScoreModel: Codable {
    enum CodingKeys: String, CodingKey {
        case cueList
        case cycles
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cueList = try container.decode([Cue].self, forKey: .cueList)
        let cycles = try container.decodeIfPresent([Cycle].self, forKey: CodingKeys.cycles) ?? []
        self.cycles = [String:Cycle](cycles.map { ($0.name, $0) }, uniquingKeysWith: { (a, b) in b })
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.cueList, forKey: .cueList)
        try container.encode(self.cycles.values.map { $0 }, forKey: CodingKeys.cycles)
    }
}

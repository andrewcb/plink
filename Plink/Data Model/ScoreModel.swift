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
        /// Evaluate some code text exactly as is
        case codeStatement(String)
        /// Call a named procedure, passing whichever arguments are sensible
        case callProcedure(String)
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
    
    public private(set) var cycleList: [Cycle]

    var onCueListChanged: (()->())? = nil
    var onCycleListChanged: (()->())? = nil

    init(cueList: [Cue] = [], cycles: [Cycle] = []) {
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
    
    mutating func replaceCycle(atIndex index: Int, with cycle: Cycle) {
        self.cycleList[index] = cycle
        self.onCycleListChanged?()
    }
    
    mutating func add(cycle: Cycle) {
        self.cycleList.append(cycle)
        self.onCycleListChanged?()
    }

    // TODO: add reordering of the cycle list, i.e., by dragging

}

extension ScoreModel.CuedAction {
    /// Construct a CuedAction given some code text; if it's just a symbol, it becomes a .callProcedure, otherwise it's a .codeStatement
    init(codeText: String) {
        let reSymbol = try! NSRegularExpression(pattern: "^[a-zA-Z$_][a-zA-Z0-9$_]*$", options: [])
        if !reSymbol.matches(in: codeText, range: NSRange(location:0, length: codeText.count)).isEmpty {
            self = .callProcedure(codeText)
        } else {
            self = .codeStatement(codeText)
        }
    }
}

extension ScoreModel.CuedAction: Equatable {}
extension ScoreModel.Cue: Equatable {}
extension ScoreModel.Cycle: Equatable {}

extension ScoreModel.CuedAction: Codable {
    enum CodingKeys: String, CodingKey {
        case code
        case procedure
    }
    
    struct DecodingError: Swift.Error { }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let code = try container.decodeIfPresent(String.self, forKey: .code) {
            self = .codeStatement(code)
        } else if let proc = try container.decodeIfPresent(String.self, forKey: .procedure) {
            self = .callProcedure(proc)
        } else {
            throw DecodingError()
        }
        
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch(self) {
        case .codeStatement(let code): try container.encode(code, forKey: .code)
        case .callProcedure(let proc): try container.encode(proc, forKey: .procedure)
        }
    }
}

extension ScoreModel.Cue: Codable {
    enum CodingKeys: String, CodingKey {
        case time
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.time = TickTime(try container.decode(Int.self, forKey: .time))
        self.action = try ScoreModel.CuedAction(from: decoder)
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
        self.action = try ScoreModel.CuedAction(from: decoder)
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
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cueList = try container.decode([Cue].self, forKey: .cueList)
        self.cycleList = try container.decodeIfPresent([Cycle].self, forKey: CodingKeys.cycles) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.cueList, forKey: .cueList)
        try container.encode(self.cycleList, forKey: .cycles)
    }
}

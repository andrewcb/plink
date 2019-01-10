//
//  WorkspaceModel.swift
//  Plink
//
//  Created by acb on 29/08/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

struct WorkspaceModel: Codable {
    
    var audioSystem: AudioSystemModel
    var metronome: MetronomeModel
    var codeSystem: CodeSystemModel
    var scoreModel: ScoreModel
    
    // AAAABBBBCCCC = A.B.C
    static let currentDocumentVersion: Int = 0x000100010000

    enum CodingKeys: String, CodingKey {
        case audioSystem
        case metronome
        case codeSystem
        case score
        case documentVersion
    }
    
    init(audioSystem: AudioSystemModel, metronome: MetronomeModel, codeSystem: CodeSystemModel, scoreModel: ScoreModel) {
        self.audioSystem = audioSystem
        self.metronome = metronome
        self.codeSystem = codeSystem
        self.scoreModel = scoreModel
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.audioSystem = try container.decode(AudioSystemModel.self, forKey: .audioSystem)
        self.metronome = try container.decode(MetronomeModel.self, forKey: .metronome)
        self.codeSystem = try container.decode(CodeSystemModel.self, forKey: .codeSystem)
        self.scoreModel = try container.decodeIfPresent(ScoreModel.self, forKey: .score) ?? ScoreModel()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(WorkspaceModel.currentDocumentVersion, forKey: .documentVersion)
        try container.encode(self.audioSystem, forKey: .audioSystem)
        try container.encode(self.metronome, forKey: .metronome)
        try container.encode(self.codeSystem, forKey: .codeSystem)
        try container.encode(self.scoreModel, forKey: .score)
    }
}

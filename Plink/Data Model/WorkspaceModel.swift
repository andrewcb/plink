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
    
    // AAAABBBBCCCC = A.B.C
    static let currentDocumentVersion: Int = 0x000100010000

    enum CodingKeys: String, CodingKey {
        case audioSystem
        case metronome
        case codeSystem
        case documentVersion
    }
    
    init(audioSystem: AudioSystemModel, metronome: MetronomeModel, codeSystem: CodeSystemModel) {
        self.audioSystem = audioSystem
        self.metronome = metronome
        self.codeSystem = codeSystem
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.audioSystem = try container.decode(AudioSystemModel.self, forKey: .audioSystem)
        self.metronome = try container.decode(MetronomeModel.self, forKey: .metronome)
        self.codeSystem = try container.decode(CodeSystemModel.self, forKey: .codeSystem)

    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(WorkspaceModel.currentDocumentVersion, forKey: .documentVersion)
        try container.encode(self.audioSystem, forKey: .audioSystem)
        try container.encode(self.metronome, forKey: .metronome)
        try container.encode(self.codeSystem, forKey: .codeSystem)
    }
}

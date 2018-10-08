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
    var transport: TransportModel
    var codeSystem: CodeSystemModel
    
    // AAAABBBBCCCC = A.B.C
    static let currentDocumentVersion: Int = 0x000100000000

    enum CodingKeys: String, CodingKey {
        case audioSystem
        case transport
        case codeSystem
        case documentVersion
    }
    
    init(audioSystem: AudioSystemModel, transport: TransportModel, codeSystem: CodeSystemModel) {
        self.audioSystem = audioSystem
        self.transport = transport
        self.codeSystem = codeSystem
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.audioSystem = try container.decode(AudioSystemModel.self, forKey: .audioSystem)
        self.transport = try container.decode(TransportModel.self, forKey: .transport)
        self.codeSystem = try container.decode(CodeSystemModel.self, forKey: .codeSystem)

    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(WorkspaceModel.currentDocumentVersion, forKey: .documentVersion)
        try container.encode(self.audioSystem, forKey: .audioSystem)
        try container.encode(self.transport, forKey: .transport)
        try container.encode(self.codeSystem, forKey: .codeSystem)
    }
}

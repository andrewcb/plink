//
//  TransportModel.swift
//  Plink
//
//  Created by acb on 22/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

struct TransportModel: Codable {
    let tempo: Double
    
    enum CodingKeys: String, CodingKey {
        case tempo
    }
    
    init(tempo: Double) {
        self.tempo = tempo
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.tempo = try container.decode(Double.self, forKey: .tempo)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.tempo, forKey: .tempo)
    }
}

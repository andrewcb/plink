//
//  CodeSystemModel.swift
//  Plink
//
//  Created by acb on 22/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

// TODO: perhaps the file should be a bundle/.zip, with the script and scrollback being files in it
struct CodeSystemModel: Codable {
    let script: String
    let scrollback: String
    
    enum CodingKeys: String, CodingKey {
        case script
        case scrollback
        case language
    }
    
    init(script: String, scrollback: String) {
        self.script = script
        self.scrollback = scrollback
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.script  = try container.decode(String.self, forKey: .script)
        self.scrollback  = try container.decode(String.self, forKey: .scrollback)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.script, forKey: .script)
        try container.encode(self.scrollback, forKey: .scrollback)
    }

}

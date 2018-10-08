//
//  AudioSystemModel.swift
//  Plink
//
//  Created by acb on 22/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

// the model of the AudioSystem specification

struct AudioSystemModel: Codable {
    struct ChannelModel: Codable {
        let name: String
        
        let gain: Float
        let pan: Float
        
        /// the preset for the instrument
        let instrument: Data?
        
        /// the presets for the inserts
        let inserts: [Data]
        
        enum CodingKeys: String, CodingKey {
            case name
            case gain
            case pan
            case instrument
            case inserts
        }
        
        init(name: String, gain: Float, pan: Float, instrument: Data?, inserts: [Data]) {
            self.name = name
            self.gain = gain
            self.pan = pan
            self.instrument = instrument
            self.inserts = inserts
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.name = try container.decode(String.self, forKey: .name)
            self.gain = try container.decode(Float.self, forKey: .gain)
            self.pan = try container.decode(Float.self, forKey: .pan)
            self.instrument = try container.decodeIfPresent(Data.self, forKey: .instrument)
            self.inserts = try container.decode([Data].self, forKey: .inserts)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.name, forKey: .name)
            try container.encode(self.gain, forKey: .gain)
            try container.encode(self.pan, forKey: .pan)
            if let inst = self.instrument {
                try container.encode(inst, forKey: .instrument)
            }
            try container.encode(self.inserts, forKey: .inserts)
        }
    }
    
    let channels: [ChannelModel]
    enum CodingKeys: String, CodingKey {
        case channels
    }
    
    init(channels: [ChannelModel]) {
        self.channels = channels
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.channels = try container.decode([ChannelModel].self, forKey: .channels)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.channels, forKey: .channels)
    }
}


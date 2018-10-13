//
//  Channel.swift
//  Plink
//
//  Created by acb on 07/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc protocol ChannelExports: JSExport {
    var instrument: JSCoreCodeEngine.Unit? { get }
}

extension JSCoreCodeEngine {

    @objc public class Channel: NSObject, ChannelExports {
        weak var channel: AudioSystem.Channel!
        weak var engine: JSCoreCodeEngine!

        init(channel: AudioSystem.Channel, engine: JSCoreCodeEngine) {
            self.channel = channel
            self.engine = engine
            super.init()
        }
        
        @objc public var instrument: Unit? {
            return self.channel.instrument.flatMap({ try? $0.getInstance() }).map { JSCoreCodeEngine.Unit(instance: $0, engine: self.engine) }
            
        }
    }
}

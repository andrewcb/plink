//
//  Unit.swift
//  Plink
//
//  Created by acb on 07/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc protocol UnitExports: JSExport {
    func sendMIDIEvent(_ b1: Int, _ b2: Int, _ b3: Int)
}


extension JSCoreCodeEngine {

    @objc public class Unit: NSObject, UnitExports {
        var instance: AudioUnitInstance
        
        init(instance: AudioUnitInstance) {
            self.instance = instance
            super.init()
        }
        
        @objc func sendMIDIEvent(_ b1: Int, _ b2: Int, _ b3: Int) {
            try? self.instance.sendMIDIEvent(UInt8(b1 & 0xff), UInt8(b2 & 0x7f), UInt8(b2 & 0x7f), atSampleOffset: 0)
        }
    }
}

//
//  Transport.swift
//  Plink
//
//  Created by acb on 07/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc protocol TransportExports: JSExport {
    var tempo: Double { get set }
    
    func setTimeout(_ block: JSValue, _ beats: Double)
}

extension JSCoreCodeEngine {
    @objc public class Transport: NSObject, TransportExports {
        weak var transport: Plink.Transport!
        
        init(transport: Plink.Transport) {
            self.transport = transport
        }
        var tempo: Double {
            get {
                return self.transport.tempo
            }
            set(v) {
                self.transport.tempo = v
            }
        }
        
        func setTimeout(_ block: JSValue, _ beats: Double) {
            self.transport.async(inBeats: beats, execute: { block.call(withArguments:[]) })
        }
        
    }
}

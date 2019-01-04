//
//  Transport.swift
//  Plink
//
//  Created by acb on 07/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc protocol MetronomeExports: JSExport {
    var tempo: Double { get set }
    
    func setTimeout(_ block: JSValue, _ beats: Double)
}

extension JSCoreCodeEngine {
    @objc public class Metronome: NSObject, MetronomeExports {
        weak var metronome: Plink.Metronome!
        
        init(metronome: Plink.Metronome) {
            self.metronome = metronome
        }
        var tempo: Double {
            get {
                return self.metronome.tempo
            }
            set(v) {
                self.metronome.tempo = v
            }
        }
        
        func setTimeout(_ block: JSValue, _ beats: Double) {
            self.metronome.async(inBeats: beats, execute: { block.call(withArguments:[]) })
        }
        
        public override var description: String {
            return "<Metronome: tempo = \(self.tempo)>"
        }
    }
}
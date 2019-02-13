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
    var tickTime: Int { get }
    var ticksPerBeat: Int { get }
    
    func setTimeout(_ block: JSValue, _ beats: Double)
}

extension JSCoreCodeEngine {
    @objc public class Metronome: NSObject, MetronomeExports {
        weak var metronome: Plink.Metronome!
        weak var scheduler: Plink.Scheduler!
        
        init(metronome: Plink.Metronome, scheduler: Plink.Scheduler) {
            self.metronome = metronome
            self.scheduler = scheduler
        }
        var tempo: Double {
            get {
                return self.metronome.tempo
            }
            set(v) {
                self.metronome.tempo = v
            }
        }
        
        var tickTime: Int {
            get {
                return self.metronome.tickTime.value
            }
        }
        
        var ticksPerBeat: Int {
            get {
                return TickTime.ticksPerBeat
            }
        }
        
        func setTimeout(_ block: JSValue, _ beats: Double) {
            guard beats.isFinite else { return }
            let ticks = Int(beats*Double(TickTime.ticksPerBeat))
            let time = self.metronome.tickTime + TickDuration(ticks)
            self.scheduler.schedule(atMetronomeTime: time, action:{ block.call(withArguments: []) })
        }
        
        public override var description: String {
            return "<Metronome: tempo = \(self.tempo)>"
        }
    }
}

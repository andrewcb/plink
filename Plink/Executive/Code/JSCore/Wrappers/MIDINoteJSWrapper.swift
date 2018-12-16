//
//  MIDINoteJSWrapper.swift
//  Plink
//
//  Created by acb on 29/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

import JavaScriptCore

@objc protocol MIDINoteExports: JSExport {
    init?(_ note: Int, velocity: Int, duration: Int, channel: Int)
}

extension JSCoreCodeEngine {
    
    @objc public class MIDINote: NSObject, MIDINoteExports {
        var note: Plink.MIDINote
        required init?(_ note: Int, velocity: Int, duration: Int, channel: Int) {
            self.note = Plink.MIDINote(note: UInt8(note), channel: UInt8(channel), velocity: UInt8(velocity), duration: TickDuration(duration))
            
        }
        
        public override var description: String {
            return self.note.description
        }
    }
    
    func setupMIDINote() {
        let midiNoteConstructor: @convention(block) (Int, Int, Int, Int) -> (Any?) = { (pitch, vel, dur, maybeChannel) in
            guard let args = JSContext.currentArguments(),
                args.count >= 3,
                // for some reason, args[0] as? Int always yields nil; hence this weird hybrid approach, where args is just used for length checking
                pitch >= 0 && pitch < 128,
                vel >= 0 && vel < 128,
                dur >= 0
            else { return nil }
            let ch = (maybeChannel >= 0 && maybeChannel < 16) ? maybeChannel : 0
            return MIDINote(pitch, velocity: vel, duration: dur, channel: ch)
        }
        
        self.ctx.setObject(unsafeBitCast(midiNoteConstructor, to: AnyObject.self), forKeyedSubscript: "MIDINote" as (NSCopying & NSObjectProtocol))
    }
}

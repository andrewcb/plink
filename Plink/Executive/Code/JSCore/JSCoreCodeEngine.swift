//
//  JSCoreCodeEngine.swift
//  Plink
//
//  Created by acb on 14/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation
import JavaScriptCore

/// A CodeLanguageEngine using JavaScript as handled by macOS' JavaScriptCore

class JSCoreCodeEngine: CodeLanguageEngine {
    
    let env: CodeEngineEnvironment
    var ctx: JSContext
    var delegate: CodeEngineDelegate?
    
    init(env: CodeEngineEnvironment) {
        self.env = env
        self.ctx = JSContext()!
        self.setupContext()
        NotificationCenter.default.addObserver(self, selector: #selector(self.setUpChannels(_:)), name: AudioSystem.channelsChangedNotification, object: nil)
    }
    
    //MARK: making the channel map
    @objc func setUpChannels(_ notification: Notification) {
        let channels = (self.env.audioSystem?.channels ?? []).map { ($0.name, JSCoreCodeEngine.Channel(channel: $0, engine: self)) }
        
        let charray = JSValue(object: channels.map { $0.1 }, in: self.ctx)!
        for (key, val) in channels {
            charray.setObject(val, forKeyedSubscript: key as (NSCopying & NSObjectProtocol))
        }
        
        self.ctx.setObject(charray, forKeyedSubscript: "$ch" as NSCopying & NSObjectProtocol)
    }
    

    
    private func setupContext() {
        
        // functions
        
        let logFunc: @convention(block) (NSString) -> () = { [weak self] msg in
            self?.delegate?.logToConsole(msg as String)
        }
        
        let getChannelFunc: @convention(block) (NSString) -> (Any?) = { [weak self] name in
            guard let self = self else { return nil }
            return self.env.audioSystem?.channelNamed(name as String).map { JSCoreCodeEngine.Channel(channel: $0, engine: self) }
        }

        let recordFunc: @convention(block) (NSString, Float32, JSValue) -> () = { [weak self] (outpath, dur, fn) in
            guard let self = self else { return }
            do {
                guard let audioSystem = self.env.audioSystem else { return }
                let frameDuration = Float32(1.0/((Float64(audioSystem.sampleRate) / Float64(audioSystem.numSamplesPerBuffer))))
                let frameCount = Int(ceilf(dur/frameDuration))
                try audioSystem.render(to: outpath as String, running: { (renderCallback) in
                    fn.call(withArguments: [])
                    // run some frames here
                    for _ in (0..<frameCount) {
                        renderCallback()
                    }
                })
            } catch {
                self.delegate?.logToConsole("error in recording: \(error)")
            }
        }
        
        /// API objects/functions set up here

        self.ctx.setObject(unsafeBitCast(logFunc, to: AnyObject.self), forKeyedSubscript: "log" as NSCopying & NSObjectProtocol)
        self.ctx.setObject(unsafeBitCast(getChannelFunc, to: AnyObject.self), forKeyedSubscript: "getChannel" as NSCopying & NSObjectProtocol)
        self.ctx.setObject(unsafeBitCast(recordFunc, to: AnyObject.self), forKeyedSubscript: "record" as NSCopying & NSObjectProtocol)
        self.ctx.setObject(Metronome(metronome: env.metronome, scheduler: env.scheduler), forKeyedSubscript: "metronome" as NSCopying & NSObjectProtocol)
        self.ctx.setObject(Scheduler(scheduler: env.scheduler, engine: self), forKeyedSubscript: "scheduler" as NSCopying & NSObjectProtocol)

        self.setupMIDINote()
        
        ctx.exceptionHandler = { [weak self] (ctx, exc) in
            if let exc = exc {
                self?.delegate?.codeLanguageExceptionOccurred("\(exc)")
            }
        }
    }
    
    func resetState() {
        self.ctx = JSContext()!
        self.setupContext()
    }
    
    func eval(script: String) {
        self.ctx.evaluateScript(script)
    }
    
    func eval(command: String) -> String? {
        let r: JSValue = self.ctx.evaluateScript(command)
        if r.isUndefined || r.isNull { return nil }
        return "\(r)"
    }
    
    func call(procedureNamed proc: String, withArguments args: [Any]) {
        if let proc = self.ctx.objectForKeyedSubscript(proc) {
            proc.call(withArguments: args)
        }
    }
}


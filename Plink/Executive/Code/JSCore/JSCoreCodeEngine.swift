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
    
    /// Create the channel map ($ch)
    @objc func setUpChannels(_ notification: Notification) {
        self.setUpChannels()
    }
    
    func setUpChannels() {
        let channels = (self.env.audioSystem?.channels ?? []).map { ($0.name, JSCoreCodeEngine.Channel(channel: $0, engine: self)) }
        
        let charray = JSValue(object: channels.map { $0.1 }, in: self.ctx)!
        for (key, val) in channels {
            charray.setObject(val, forKeyedSubscript: key as (NSCopying & NSObjectProtocol))
        }
        
        self.ctx.setObject(charray, forKeyedSubscript: "$ch" as NSCopying & NSObjectProtocol)
    }

    /// Establish the context, setting up named objects at its top level.
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
            guard
                let self = self,
                let audioSystem = self.env.audioSystem
            else { return }
            do {
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
        
        let diagChannelsDumpFunc: @convention(block) () -> () = { [weak self] () in
            guard
                let self = self,
                let audioSystem = self.env.audioSystem,
                let delegate = self.delegate
            else { return }
            for (i, ch) in audioSystem.channels.enumerated() {
                delegate.logToConsole("\(i): \(ch.name): \(ch.instrument?.description ?? "-") |> [\(ch.inserts.map { $0.description }.joined(separator: ", "))]")
            }

        }
        
        let diagGraphDumpFunc: @convention(block) () -> () = { [weak self] () in
            guard
                let self = self,
                let audioSystem = self.env.audioSystem,
                let delegate = self.delegate
            else { return }
            audioSystem.graph.dump(delegate.logToConsole)
        }
        
        ///MARK: API objects/functions set up here

        self.ctx.setObject(unsafeBitCast(logFunc, to: AnyObject.self), forKeyedSubscript: "log" as NSCopying & NSObjectProtocol)
        self.ctx.setObject(unsafeBitCast(getChannelFunc, to: AnyObject.self), forKeyedSubscript: "getChannel" as NSCopying & NSObjectProtocol)
        self.ctx.setObject(unsafeBitCast(recordFunc, to: AnyObject.self), forKeyedSubscript: "record" as NSCopying & NSObjectProtocol)
        self.ctx.setObject(Metronome(metronome: env.metronome, scheduler: env.scheduler), forKeyedSubscript: "metronome" as NSCopying & NSObjectProtocol)
        self.ctx.setObject(Scheduler(scheduler: env.scheduler, engine: self), forKeyedSubscript: "scheduler" as NSCopying & NSObjectProtocol)

        self.setupMIDINote()
        self.setUpChannels()
        
        // MARK: the $diag object
        // TODO: configure this out in production builds
        let diag = JSValue(newObjectIn: ctx)
        diag?.setObject(diagChannelsDumpFunc, forKeyedSubscript: "cdump" as NSCopying & NSObjectProtocol)
        diag?.setObject(diagGraphDumpFunc, forKeyedSubscript: "gdump" as NSCopying & NSObjectProtocol)
        self.ctx.setObject(diag, forKeyedSubscript: "$diag" as NSCopying & NSObjectProtocol)
        
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
    
    func set(variableNamed key: String, to value: CodeValueConvertible) {
        let jsval: JSValue
        if let intValue = value as? Int {
            jsval = JSValue(int32: Int32(intValue), in: self.ctx)
        }
        else {
            fatalError("Unsupported CodeValueConvertible: \(value)")
        }
        self.ctx.setObject(jsval, forKeyedSubscript: key as NSCopying & NSObjectProtocol)
    }
}


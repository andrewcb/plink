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
    }
    
    private func setupContext() {
        
        // functions
        
        let logFunc: @convention(block) (NSString) -> () = { [weak self] msg in
            self?.delegate?.logToConsole(msg as String)
        }
        
        let getChannelFunc: @convention(block) (NSString) -> (Any?) = { [weak self] name in
            return self?.env.audioSystem?.channelNamed(name as String).map { JSCoreCodeEngine.Channel(channel: $0) }
        }

        
        /// API objects/functions set up here

        self.ctx.setObject(unsafeBitCast(logFunc, to: AnyObject.self), forKeyedSubscript: "log" as NSCopying & NSObjectProtocol)
        self.ctx.setObject(unsafeBitCast(getChannelFunc, to: AnyObject.self), forKeyedSubscript: "getChannel" as NSCopying & NSObjectProtocol)
        self.ctx.setObject(Transport(transport: env.transport), forKeyedSubscript: "transport" as NSCopying & NSObjectProtocol)
        self.ctx.setObject(Scheduler(scheduler: env.scheduler, engine: self), forKeyedSubscript: "scheduler" as NSCopying & NSObjectProtocol)

        
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
}


//
//  CodeSystem.swift
//  Plink
//
//  Created by acb on 07/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

class CodeSystem {
    var script: String = "" {
        didSet {
            NotificationCenter.default.post(name: CodeSystem.scriptStateChanged, object: nil)
        }
    }
    var scrollback: String?
    var codeEngine: CodeLanguageEngine?
    
    init(env: CodeEngineEnvironment) {
        let jsEngine = JSCoreCodeEngine(env: env)
        self.codeEngine = jsEngine
    }
    
    deinit {
        self.codeEngine = nil
    }
    
    func snapshot() -> CodeSystemModel {
        return CodeSystemModel(script: self.script, scrollback: self.scrollback ?? "")
    }
    
    func set(from model: CodeSystemModel) {
        self.script = model.script
        self.scrollback = model.scrollback
    }
    
    //MARK: the evaluation of the current script, now handled here
    
    /// the last script text to have been eval'd by the code engine
    var lastEvaluatedScript: String? = nil
    
    /// has the script changed since the last time it was eval'd?
    var scriptIsUnevaluated: Bool { return self.script != (self.lastEvaluatedScript ?? "") }
    
    /// posted when the script text changes or the script is eval'd
    static let scriptStateChanged = Notification.Name("CodeSystem.ScriptStateChanged")
    
    func evalScript() {
        self.codeEngine?.eval(script: self.script)
        self.lastEvaluatedScript = self.script
        NotificationCenter.default.post(name: CodeSystem.scriptStateChanged, object: nil)
    }
}

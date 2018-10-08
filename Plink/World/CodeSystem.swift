//
//  CodeSystem.swift
//  Plink
//
//  Created by acb on 07/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

class CodeSystem {
    var script: String = ""
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
}

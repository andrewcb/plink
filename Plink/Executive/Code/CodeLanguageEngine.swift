//
//  CodeLanguageEngine.swift
//  Plink
//
//  Created by acb on 14/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//
//  The base protocol implementing a language engine. This is a stateful object which interprets scripts and one-off commands

import Foundation

protocol CodeLanguageEngine {
    
    /// The CodeEngineDelegate
    var delegate: CodeEngineDelegate? { get set }
    
    /// Reset the language state to a fresh one
    func resetState()
    
    /// evaluate a script, which may consist of multiple statements and may be used to establish definitions
    func eval(script: String)
    
    /// evaluate a single command; returns output, if any
    func eval(command: String) -> String?
    
    /// call a named procedure, passing given arguments
    func call(procedureNamed proc: String, withArguments args: [Any])
    
    /// set a variable to a CodeValueConvertible value
    func set(variableNamed key: String, to value: CodeValueConvertible)
}

extension CodeLanguageEngine {
    func run(action: CodeEngineAction, withArgs args: [Any]?) {
        switch(action) {
        case .codeStatement(let code):
           _ = self.eval(command: code)
        case .callProcedure(let proc):
            self.call(procedureNamed: proc, withArguments: args ?? [])
        }
    }
}

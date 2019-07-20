//
//  CodeEngineAction.swift
//  Plink
//
//  Created by acb on 2019-05-26.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Foundation

// An action that may be invoked in the CodeEngine
enum CodeEngineAction {
    /// Evaluate some code text exactly as is
    case codeStatement(String)
    /// Call a named procedure, passing whichever arguments are sensible
    case callProcedure(String)
}

extension CodeEngineAction {
    /// Construct a CodeEngineAction given some code text; if it's just a symbol, it becomes a .callProcedure, otherwise it's a .codeStatement
    init(codeText: String) {
        let codeText = codeText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let reSymbol = try! NSRegularExpression(pattern: "^[a-zA-Z$_][a-zA-Z0-9$_]*$", options: [])
        if !reSymbol.matches(in: codeText, range: NSRange(location:0, length: codeText.count)).isEmpty {
            self = .callProcedure(codeText)
        } else {
            self = .codeStatement(codeText)
        }
    }
}

extension CodeEngineAction: Equatable {}

extension CodeEngineAction: Hashable {}

extension CodeEngineAction: Codable {
    enum CodingKeys: String, CodingKey {
        case code
        case procedure
    }
    
    struct DecodingError: Swift.Error { }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let code = try container.decodeIfPresent(String.self, forKey: .code) {
            self = .codeStatement(code)
        } else if let proc = try container.decodeIfPresent(String.self, forKey: .procedure) {
            self = .callProcedure(proc)
        } else {
            throw DecodingError()
        }
        
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch(self) {
        case .codeStatement(let code): try container.encode(code, forKey: .code)
        case .callProcedure(let proc): try container.encode(proc, forKey: .procedure)
        }
    }
}

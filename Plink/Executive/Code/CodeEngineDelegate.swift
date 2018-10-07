//
//  CodeEngineDelegate.swift
//  Plink
//
//  Created by acb on 14/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

/// The protocol that 
protocol CodeEngineDelegate {
    // log a message to the console
    func logToConsole(_ message: String)
    // an exception happened within the language
    func codeLanguageExceptionOccurred(_ message: String)
}

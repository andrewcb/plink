//
//  REPLViewController.swift
//  Plink
//
//  Created by acb on 28/12/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

class REPLViewController: NSViewController {
    @IBOutlet var replView: REPLView!
    
    var font: NSFont = NSFont(name: "Monaco", size: 13.0) ?? NSFont.systemFont(ofSize: 13)
    
    var codeEngine: CodeLanguageEngine? {
        return self.activeDocument?.codeSystem.codeEngine
    }
    
    let evalQueue = DispatchQueue(label: "REPLViewController.eval", qos: DispatchQoS.background, attributes: DispatchQueue.Attributes.concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit  , target: nil)
    
    override func viewDidLoad() {
        self.replView.font = self.font
        self.replView.backgroundColor = .scrollbackBackground
        self.replView.inputBackgroundColor = .codeBackground
        self.replView.outputColor = .codeRegularText
        self.replView.errorColor = .codeErrorText
        self.replView.echoColor = .codeEchoText
        self.replView.restoredScrollbackColor = .scrollbackRestoredText
        self.replView?.restoredScrollbackDelimiter  = "————————"
        
        self.replView?.outputRestoredScrollback(self.activeDocument?.codeSystem.scrollback ?? "")
        
        self.replView.evaluator = { [weak self] (line) in
            guard let codeEngine = self?.codeEngine else { return nil }
            self?.evalQueue.async {
                if let output = codeEngine.eval(command: line) {
                    DispatchQueue.main.async {
                        self?.replView.println(response: .output(output))
                    }
                }// .map { .output($0) }
            }
            return nil
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.activeDocument?.codeSystem.codeEngine?.delegate = self
    }
}

extension REPLViewController: CodeEngineDelegate {
    func logToConsole(_ message: String) {
        DispatchQueue.main.async {
            self.replView.printOutputLn(message)
            self.activeDocument?.codeSystem.scrollback = self.replView.scrollbackTextView.string
        }
    }
    
    func codeLanguageExceptionOccurred(_ message: String) {
        DispatchQueue.main.async {
            self.replView.printErrorLn(message)
            self.activeDocument?.codeSystem.scrollback = self.replView.scrollbackTextView.string
        }
    }
}


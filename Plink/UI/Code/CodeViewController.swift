//
//  CodeViewController.swift
//  Plink
//
//  Created by acb on 06/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

class CodeViewController: NSViewController {
    @IBOutlet var sourceTextView: NSTextView!
    @IBOutlet var replView: REPLView!
    @IBOutlet var reloadButton: ColorfulTextButton!
    @IBOutlet var splitView: NSSplitView!
    
    var font: NSFont = NSFont(name: "Monaco", size: 13.0) ?? NSFont.systemFont(ofSize: 13)

    var codeEngine: CodeLanguageEngine? {
        return self.activeDocument?.codeSystem.codeEngine
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        splitView.subviews[0].wantsLayer = true
        splitView.subviews[0].layer?.backgroundColor = NSColor.codeBackground.cgColor

        self.activeDocument?.codeSystem.codeEngine?.delegate = self

        self.sourceTextView.font = self.font
        self.sourceTextView.backgroundColor = .codeBackground
        self.sourceTextView.textColor = .codeRegularText
        self.sourceTextView.insertionPointColor = .codeRegularText

        self.sourceTextView.isAutomaticQuoteSubstitutionEnabled = false
        self.sourceTextView.isGrammarCheckingEnabled = false
        self.sourceTextView.isAutomaticDashSubstitutionEnabled = false
        self.sourceTextView.isAutomaticTextCompletionEnabled = false
        self.sourceTextView.isAutomaticDataDetectionEnabled = false
        self.sourceTextView.isAutomaticTextReplacementEnabled = false
        self.sourceTextView.isAutomaticSpellingCorrectionEnabled = false
        self.sourceTextView.isRichText = false
        
        // REPL view
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
            self?.codeEngine?.eval(command: line).map { .output($0) }
        }
    }

    @IBAction func doReload(_ sender: Any) {
        self.codeEngine?.resetState()
        self.codeEngine?.eval(script: self.sourceTextView.string)
    }
}

extension CodeViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        self.activeDocument?.codeSystem.script = self.sourceTextView.string
    }
}

extension CodeViewController: CodeEngineDelegate {
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


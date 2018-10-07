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

    override func viewWillAppear() {
        super.viewWillAppear()
        
        splitView.subviews[0].wantsLayer = true
        splitView.subviews[0].layer?.backgroundColor = NSColor.codeBackground.cgColor

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
        
    }

    @IBAction func doReload(_ sender: Any) {
    }
}


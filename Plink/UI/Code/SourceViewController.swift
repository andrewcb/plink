//
//  SourceViewController.swift
//  Plink
//
//  Created by acb on 28/12/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

class SourceViewController: NSViewController {
    @IBOutlet var sourceTextView: NSTextView!
    @IBOutlet var reloadButton: ColorfulTextButton!
    
    var font: NSFont = NSFont(name: "Monaco", size: 13.0) ?? NSFont.systemFont(ofSize: 13)
    
    var codeEngine: CodeLanguageEngine? {
        return self.activeDocument?.codeSystem.codeEngine
    }
    
    let evalQueue = DispatchQueue(label: "CodeViewController.eval", qos: DispatchQoS.background, attributes: DispatchQueue.Attributes.concurrent, autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit  , target: nil)
    
    override func viewDidLoad() {
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.codeBackground.cgColor
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.sourceTextView.font = self.font
        self.sourceTextView.backgroundColor = .codeBackground
        self.sourceTextView.textColor = .codeRegularText
        self.sourceTextView.insertionPointColor = .codeRegularText
        self.sourceTextView.string = self.activeDocument?.codeSystem.script ?? ""
        
        self.sourceTextView.isAutomaticQuoteSubstitutionEnabled = false
        self.sourceTextView.isGrammarCheckingEnabled = false
        self.sourceTextView.isAutomaticDashSubstitutionEnabled = false
        self.sourceTextView.isAutomaticTextCompletionEnabled = false
        self.sourceTextView.isAutomaticDataDetectionEnabled = false
        self.sourceTextView.isAutomaticTextReplacementEnabled = false
        self.sourceTextView.isAutomaticSpellingCorrectionEnabled = false
        self.sourceTextView.isRichText = false
    }
    
    @IBAction func doReload(_ sender: Any) {
        self.codeEngine?.eval(script: self.sourceTextView.string)
    }
}

extension SourceViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        self.activeDocument?.codeSystem.script = self.sourceTextView.string
    }
}

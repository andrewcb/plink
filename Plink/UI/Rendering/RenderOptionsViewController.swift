//
//  RenderOptionsViewController.swift
//  Plink
//
//  Created by acb on 11/03/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Cocoa

class RenderOptionsViewController: NSViewController {
    
    @IBOutlet var startTime: NSTextField!
    @IBOutlet var duration: NSTextField!
    @IBOutlet var codeLine: NSTextField!
    @IBOutlet var commandTime: NSTextField!
    @IBOutlet var subjectScoreRadioButton: NSButton!
    @IBOutlet var subjectCommandRadioButton: NSButton!
    @IBOutlet var runOutEnable: NSButton!
    @IBOutlet var runOutMaxTime: NSTextField!
    
    enum TextInputTag: Int {
        case scoreStartTime = 1
        case scoreDuration = 2
        case commandLine = 3
        case commandTime = 4
        case runOutMaxTime = 5
    }
    
    // tag -> (default value, validator)
    fileprivate let textFieldSpecs: [TextInputTag: (String, ((String)->Bool))] = [
        .scoreStartTime : ("0",  { TickTimeFormattingService.sharedInstance.parse(string:$0) != nil }),
        .scoreDuration  : ("1",  { TickTimeFormattingService.sharedInstance.parse(string:$0) != nil }),
        .commandLine    : ("", {_ in true}),
        .commandTime    : ("1", { Float($0) != nil} ),
        .runOutMaxTime  : ("1", { Float($0) != nil} )
    ]
    
    // the last-known-good value of a text field, by tag
    fileprivate var lastGoodValue: [TextInputTag: String] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for textField in [self.startTime, self.duration, self.codeLine, self.commandTime] {
            textField!.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(self.textClicked(_:))))
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        for (tag, spec) in self.textFieldSpecs {
            guard let textField = self.view.viewWithTag(tag.rawValue) as? NSTextField else { continue }
            textField.stringValue = spec.0
        }
    }
    
    @objc func textClicked(_ sender: NSClickGestureRecognizer) {
        guard
            let textField = sender.view as? NSTextField,
            let tagValue = TextInputTag(rawValue: textField.tag)
        else { return }
        switch(tagValue) {
        case .commandLine, .commandTime:
            self.subjectCommandRadioButton.state = .on
            self.renderSubjectCheckBoxChanged(self.subjectCommandRadioButton)
            textField.becomeFirstResponder()
        case .scoreStartTime, .scoreDuration:
            self.subjectScoreRadioButton.state = .on
            self.renderSubjectCheckBoxChanged(self.subjectScoreRadioButton)
            textField.becomeFirstResponder()
        default: break
        }

    }
    
    var requestSubject: World.RenderRequest.Subject {
        if self.subjectScoreRadioButton.state == .on {
            let start = TickTimeFormattingService.sharedInstance.parse(string: self.startTime.stringValue) ?? 0
            let duration = TickTimeFormattingService.sharedInstance.parse(string: self.duration.stringValue) ?? 0
            return .score(start,duration)
        } else {
            assert(self.subjectCommandRadioButton.state == .on)
            return .command(self.codeLine.stringValue, self.commandTime.doubleValue)
        }
    }
    var requestOptions: World.RenderRequest.Options {
        if self.runOutEnable.state == .on {
            return World.RenderRequest.Options(maxDecay: self.runOutMaxTime.doubleValue)
        } else {
            return .default
        }
    }
    
    @IBAction func runOutCheckBoxChanged(_ sender: NSButton) {
        self.runOutMaxTime.isEnabled = self.runOutEnable.state == .on
    }
    
    @IBAction func renderSubjectCheckBoxChanged(_ sender: NSButton) {
        self.startTime.isEnabled = (self.subjectScoreRadioButton.state == .on)
        self.duration.isEnabled = (self.subjectScoreRadioButton.state == .on)
        self.codeLine.isEnabled = (self.subjectCommandRadioButton.state == .on)
        self.commandTime.isEnabled = (self.subjectCommandRadioButton.state == .on)
    }
}

extension RenderOptionsViewController: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        guard
            let textField = obj.object as? NSTextField,
            let tagValue = TextInputTag(rawValue: textField.tag),
            let spec = self.textFieldSpecs[tagValue]
        else { return }
        if spec.1(textField.stringValue) {
            self.lastGoodValue[tagValue] = textField.stringValue
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard
            let textField = obj.object as? NSTextField,
            let tagValue = TextInputTag(rawValue: textField.tag),
            let spec = self.textFieldSpecs[tagValue]
        else { return }
        if spec.1(textField.stringValue) {
            self.lastGoodValue[tagValue] = textField.stringValue
        } else {
            textField.stringValue = self.lastGoodValue[tagValue] ?? spec.0
        }
    }
}

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
    
    /// The default time value, if no valid one exists, for a time input TextField, indexed by its Tag value.
    fileprivate let defaultTimeValue: [Int:TickTime] = [
        0: 0,
        1: TickTime(beats: 1, ticks: 0)
    ]
    
    override func viewWillAppear() {
        super.viewWillAppear()
        for textField in [self.startTime, self.duration] {
            textField!.stringValue = TickTimeFormattingService.sharedInstance.format(time: self.defaultTimeValue[textField!.tag] ?? 0)
        }
    }
    
    var requestSubject: ActiveDocument.RenderRequest.Subject {
        let start = TickTimeFormattingService.sharedInstance.parse(string: self.startTime.stringValue) ?? 0
        let duration = TickTimeFormattingService.sharedInstance.parse(string: self.duration.stringValue) ?? 0
        return .score(start,duration)
    }
    var requestOptions: ActiveDocument.RenderRequest.Options {
        return .default // TODO
    }
}

extension RenderOptionsViewController: NSTextFieldDelegate {
    
    func controlTextDidEndEditing(_ obj: Notification) {
        guard
            let textField = obj.object as? NSTextField,
            let defaultTime = self.defaultTimeValue[textField.tag]
        else { return }
        textField.stringValue = TickTimeFormattingService.sharedInstance.format(time: TickTimeFormattingService.sharedInstance.parse(string: textField.stringValue) ?? defaultTime)
    }
}

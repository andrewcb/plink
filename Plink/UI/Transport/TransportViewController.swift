//
//  TransportViewController.swift
//  Plink
//
//  Created by acb on 06/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

class TransportViewController: NSViewController {
    @IBOutlet var playButton: NSButton!
    @IBOutlet var stopButton: NSButton!
    @IBOutlet var positionLabel: NSTextField!
    @IBOutlet var tempoField: NSTextField!
    @IBOutlet var tempoStepper: NSStepper!
    
    @IBAction func playButtonPressed(_ sender: Any) {
    }
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func tempoValueChanged(_ sender: NSControl) {
        print("tempo value changed: \(sender.doubleValue)")
    }

}

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

    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.transportTempoChanged()
        self.activeDocument?.transport.onTempoChange = { self.transportTempoChanged() }
        self.activeDocument?.transport.onRunningStateChange = { self.transportRunningStateChanged() }
        self.activeDocument?.transport.clients.append(self)
    }

    func transportTempoChanged() {
        guard let transport = self.activeDocument?.transport else { return }
        self.tempoField.doubleValue = transport.tempo
        self.tempoStepper.doubleValue = transport.tempo
    }
    
    func transportRunningStateChanged() {
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        self.activeDocument?.transport.running = true
    }
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        self.activeDocument?.transport.running = true
    }
    
    @IBAction func tempoValueChanged(_ sender: NSControl) {
        guard let transport = self.activeDocument?.transport else { return }
        if sender.doubleValue != 0.0 {
            transport.tempo = sender.doubleValue
        }
    }
}

extension TransportViewController: TransportClient {
    func runFor(time: TickTime) {
        DispatchQueue.main.async {
            self.positionLabel.stringValue = "\(time.beatValue).\(time.tickValue)"
        }
    }
}


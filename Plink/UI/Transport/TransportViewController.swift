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
    @IBOutlet var levelMeter: LevelMeterView!

    var levelUpdateTimer: Timer?
    
    override func viewWillAppear() {
        super.viewWillAppear()
        self.levelMeter.orientation = .horizontal
        self.transportTempoChanged()
        self.activeDocument?.transport.onTempoChange = { self.transportTempoChanged() }
        self.activeDocument?.transport.onRunningStateChange = { self.transportRunningStateChanged() }
        self.activeDocument?.transport.onRunningTick.append( { self.runFor(time: $0) })

        self.levelUpdateTimer = Timer.scheduledTimer(timeInterval: 0.04, target: self, selector: #selector(self.updateLevels), userInfo: nil, repeats: true)

    }

    override func viewWillDisappear() {
        self.levelUpdateTimer?.invalidate()
        self.levelUpdateTimer = nil
        super.viewWillDisappear()
    }
    
    @objc func updateLevels() {
        guard let audioSystem = self.activeDocument?.audioSystem else { return }
        guard let master = audioSystem.masterLevel else { print("No level returned"); return }
        self.levelMeter.levelReading = master        
    }
    func transportTempoChanged() {
        guard let transport = self.activeDocument?.transport else { return }
        self.tempoField.doubleValue = transport.tempo
        self.tempoStepper.doubleValue = transport.tempo
    }
    
    func transportRunningStateChanged() {
    }
    
    @IBAction func playButtonPressed(_ sender: Any) {
        self.activeDocument?.transport.startInPlace()
    }
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        self.activeDocument?.transport.stop()
    }
    
    @IBAction func tempoValueChanged(_ sender: NSControl) {
        guard let transport = self.activeDocument?.transport else { return }
        if sender.doubleValue != 0.0 {
            transport.tempo = sender.doubleValue
        }
    }

    /// Receive a running program time
    func runFor(time: TickTime) {
        DispatchQueue.main.async {
            self.positionLabel.stringValue = "\(time.beatValue).\(time.tickValue)"
        }
    }
}


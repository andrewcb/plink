//
//  Transport.swift
//  Plink
//
//  Created by acb on 29/12/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

/** This handles the transport: the play position, play state and such; it also owns the Score, and is responsible for playing it */
public class Transport {
    /// The clock transmission state: i.e., how the clock gets converted to the program position, if at all
    enum TransmissionState {
        case stopped(TickTime)  // Stopped; the value is the tick time
        case starting(TickTime) // will start at the next tick from the given time
        case running(TickOffset) // pos = masterTickTime+offset
    }
    
    var transmissionState: TransmissionState = .stopped(0) {
        didSet(old) {
            print("transmissionState: \(old) -> \(self.transmissionState)")
        }
    }

    /// the metronome
    var metronome: Metronome
    
    var score: ScoreModel
    
    static let cueListChanged = Notification.Name("Transport.CueListChanged")
    
    init(metronome: Metronome) {
        self.metronome = metronome
        self.score = ScoreModel(cueList: [])
        self.score.onCueListChanged = {
            NotificationCenter.default.post(name: Transport.cueListChanged, object: nil)
        }
    }

    //MARK: Transmission copntrol
    public func startInPlace() {
        if case let .stopped(t) = self.transmissionState {
            self.transmissionState = .starting(t)
        }
    }
    
    public func rewindAndStart() {
        self.transmissionState = .starting(0)
    }
    
    public func stop() {
        self.transmissionState = .stopped(self.programPosition)
    }
    
    //MARK:
    

    /// The program position
    var programPosition: TickTime {
        switch(self.transmissionState) {
        case .stopped(let t): return t
        case .starting(let t): return t
        case .running(let offset): return metronome.tickTime + offset
        }
    }

    //#MARK: notifications
    public var onRunningStateChange: (()->())?

    /// callbacks to be notified of a tick if the state is currently running
    public var onRunningTick: [((TickTime)->())] = []
    

    /// Handle a tick from the metronome
    func metronomeTick(_ time: TickTime) {
        if case let .starting(t) = self.transmissionState {
            self.transmissionState = .running(t-self.metronome.tickTime)
        }
        if case let .running(offset) = self.transmissionState {
            let pos = self.programPosition
            for client in self.onRunningTick {
                client(pos)
            }
        }

    }
}

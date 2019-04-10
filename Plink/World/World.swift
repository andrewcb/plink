//
//  World.swift
//  Plink
//
//  Created by acb on 06/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa
import CoreAudio
import AudioToolbox

/**
 The World is the open document in memory, and the objects constructed from it; it owns things such as the audio setup and transport which do not belong to a specific view or window.
 */

class World: NSDocument {
    
    let audioSystem: AudioSystem? = try? AudioSystem()
    let metronome: Metronome = Metronome()
    let transport: Transport
    let codeSystem: CodeSystem
    let scheduler: Scheduler = Scheduler()

    override init() {
        
        self.transport = Transport(metronome: self.metronome)
        self.codeSystem = CodeSystem(env: CodeEngineEnvironment(audioSystem: self.audioSystem, metronome: self.metronome, transport: self.transport, scheduler: self.scheduler))
        super.init()
        self.transport.onRunningTick.append( { self.scheduler.runFor(time: $0) })
        self.metronome.onTick.append(contentsOf: [
            { self.transport.metronomeTick($0) },
            { self.scheduler.metronomeTick($0) }
        ])
        
        // TODO: perhaps another object should handle this and route it appropriately?
        self.transport.cuedActionCallback = { (action, args) in
            switch(action) {
            case .codeStatement(let code):
                _ = self.codeSystem.codeEngine?.eval(command: code)
            case .callProcedure(let proc):
                guard let codeEngine = self.codeSystem.codeEngine else { return }
                codeEngine.call(procedureNamed: proc, withArguments: args ?? [])
            }
        }
        
        self.transport.onRunningStateChange = {
            if case .starting(_) = self.transport.transmissionState {
                self.metronome.tempo = self.transport.score.baseTempo
            }
        }
        
        self.audioSystem?.onPreRender = metronome.advance
        self.audioSystem?.onAudioInterruption = scheduler.clearPendingMetroActions
        
        self.hasUndoManager = false
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        self.addWindowController(windowController)
    }
    
    // MARK: save/restore

    private func snapshot() throws -> WorldModel {
        // FIXME: forced unwrap
        return WorldModel(audioSystem: try self.audioSystem?.snapshot() ?? AudioSystemModel(), metronome: self.metronome.snapshot(), codeSystem: self.codeSystem.snapshot(), scoreModel: self.transport.score)
    }
    
    private func set(from snapshot: WorldModel) throws {
        try self.audioSystem?.set(from: snapshot.audioSystem)
        self.metronome.set(from: snapshot.metronome)
        self.codeSystem.set(from: snapshot.codeSystem)
        self.transport.loadScore(from:snapshot.scoreModel)
        if self.codeSystem.scriptIsUnevaluated {
            self.codeSystem.evalScript()
        }
    }
    
    override func data(ofType typeName: String) throws -> Data {
        let snapshot = try self.snapshot()
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml // for debugging
        return try encoder.encode(snapshot)
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        
        // Before we feed the data to our Decodable model, we check its version number and, if it's old, migrate it
        
        let data = try migratedData(from: data, toVersion: WorldModel.currentDocumentVersion)
        
        let decoder = PropertyListDecoder()
        let decoded = try decoder.decode(WorldModel.self, from: data)
        Swift.print("Decoded: \(decoded)")
        
        try self.set(from: decoded)
    }
    
    /// MARK: the rendering of various things within this environment
    
    /// A request to render something (a segment of score, the result of running some code) to an output
    struct RenderRequest {
        enum Subject {
            /// render the current score, from a start time, for a duration
            case score(TickTime, TickDuration)
            /// execute a command in the code system
            case command(String, Double)
        }
        
        enum Destination {
            case file(URL)
        }
        
        struct Options {
            /// maximum time in seconds to keep rendering after ceasing the  until the sound fades to DC
            let maxDecay: Double
            
            static let `default` = Options(maxDecay: 0)
        }
        
        let subject: Subject
        let destination: Destination
        let options: Options
    }
    
    /// a status sent to the status callback
    enum RenderStatus {
        case started
        case progress(Double)
        case completed
    }
    typealias RenderStatusCallback = ((RenderStatus)->())
    
    
    func render(_ request: RenderRequest, statusCallback: RenderStatusCallback) throws {
        guard let audioSystem = self.audioSystem else { fatalError("No audioSystem :-/") }
        // stop transport if needed
        self.transport.stop()
        
        let runoutMode: AudioSystem.RenderRunoutMode = request.options.maxDecay > 0 ? AudioSystem.RenderRunoutMode.toSilence(512, Int(ceil(request.options.maxDecay/audioSystem.bufferDuration))) : .none
        let recordingFunc: ((() -> ()) -> ()) throws -> ()
        switch(request.destination) {
        case .file(let url): recordingFunc = { fn in try audioSystem.render(toURL: url, runoutMode: runoutMode, running: fn) }
        }
        
        switch(request.subject) {
            
        case .score(let startPos, let duration):
            try recordingFunc { [weak self] (pullFrame) in
                guard let self = self else { return }
                self.transport.start(at: startPos)
                while self.transport.programPosition < startPos+duration {
                    pullFrame()
                    if duration>0 {
                        statusCallback(RenderStatus.progress(Double((self.transport.programPosition-startPos).value)/Double(duration.value)))
                    }
//                    Swift.print("* pos = \(self.transport.programPosition)")
//                    usleep(5000)
                }
                self.transport.stop()
            }
            
        case .command(let cmd, let time):
            let numFrames = Int(ceil(time/audioSystem.bufferDuration))
            try recordingFunc { [weak self] (pullFrame) in
                guard let self = self else { return }
                _ = self.codeSystem.codeEngine?.eval(command: cmd)
                for _ in 0..<numFrames {
                    pullFrame()
                }
            }
        }
        
    }
}


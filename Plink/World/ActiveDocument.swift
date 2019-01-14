//
//  Document.swift
//  Plink
//
//  Created by acb on 06/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa
import CoreAudio
import AudioToolbox

/**
 The ActiveDocument is the open document in memory, and the objects constructed from it; it owns things such as the audio setup and transport which do not belong to a specific view or window.
 */

class ActiveDocument: NSDocument {
    
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
                self.codeSystem.codeEngine?.eval(command: code)
            case .callProcedure(let proc):
                guard let codeEngine = self.codeSystem.codeEngine else { return }
                Swift.print("calling \(proc)()")
                codeEngine.call(procedureNamed: proc, withArguments: args ?? [])
            }
        }
        
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

    private func snapshot() throws -> WorkspaceModel {
        // FIXME: forced unwrap
        return WorkspaceModel(audioSystem: try self.audioSystem!.snapshot(), metronome: self.metronome.snapshot(), codeSystem: self.codeSystem.snapshot(), scoreModel: self.transport.score)
    }
    
    private func set(from snapshot: WorkspaceModel) throws {
        try self.audioSystem?.set(from: snapshot.audioSystem)
        self.metronome.set(from: snapshot.metronome)
        self.codeSystem.set(from: snapshot.codeSystem)
        self.transport.score = snapshot.scoreModel
    }
    
    override func data(ofType typeName: String) throws -> Data {
        let snapshot = try self.snapshot()
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml // for debugging
        return try encoder.encode(snapshot)
    }
    
    override func read(from data: Data, ofType typeName: String) throws {
        
        // Before we feed the data to our Decodable model, we check its version number and, if it's old, migrate it
        
        let data = try migratedData(from: data, toVersion: WorkspaceModel.currentDocumentVersion)
        
        let decoder = PropertyListDecoder()
        let decoded = try decoder.decode(WorkspaceModel.self, from: data)
        Swift.print("Decoded: \(decoded)")
        
        try self.set(from: decoded)
    }

}


//
//  AudioSystem.Channel.swift
//  Plink
//
//  Created by acb on 09/04/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Foundation
import AudioToolbox

extension AudioSystem {
    /// A Channel, currently consisting of an instrument and some inserts
    class Channel {
        var name: String {
            didSet {
                self.audioSystem?.channelsChanged()
            }
        }
        var audioSystem: AudioSystem? = nil
        var index: Int = -1
        var instrument: AudioUnitGraph<ManagedAudioUnitInstance>.Node? = nil {
            didSet(prev) {
                guard prev != self.instrument else { return }
                do {
                    try self.audioSystem?.stopGraph()
                    try prev?.disconnectAll()
                    try prev?.removeFromGraph()
                    if let firstInsert = inserts.first {
                        try self.instrument?.connect(to: firstInsert)
                    }
                    self._headNode = self.findHeadNode()
                    try self.audioSystem?.startGraph()
                } catch {
                    fatalError("failed to disconnect/connect nodes: \(error)")
                }
            }
        }
        var _inserts: [AudioUnitGraph<ManagedAudioUnitInstance>.Node] = []
        var inserts: [AudioUnitGraph<ManagedAudioUnitInstance>.Node] {
            return self._inserts
        }
        // methods for adding inserts
        func add(insert: AudioUnitGraph<ManagedAudioUnitInstance>.Node) throws {
            let lastHead = self.headNode
            self._inserts.append(insert)
            try self.audioSystem?.stopGraph()
            try lastHead?.disconnectOutput()
            try lastHead?.connect(to: insert)
            self._headNode = self.findHeadNode()
            try self.audioSystem?.startGraph()
            
        }
        
        /// The node that's at the end of the chain
        var _headNode: AudioUnitGraph<ManagedAudioUnitInstance>.Node? {
            didSet(prev) {
                self.onHeadNodeChanged?(self, prev)
                print("head node changed:")
                audioSystem!.graph.dump()
            }
        }
        var headNode: AudioUnitGraph<ManagedAudioUnitInstance>.Node? {
            return self._headNode
        }
        private func findHeadNode() -> AudioUnitGraph<ManagedAudioUnitInstance>.Node? {
            return self.inserts.last ?? self.instrument
        }
        
        // notification method; called with the Channel and
        var onHeadNodeChanged: ((Channel,AudioUnitGraph<ManagedAudioUnitInstance>.Node?)->())? = nil
        
        init(name: String, instrument: AudioUnitGraph<ManagedAudioUnitInstance>.Node? = nil, inserts: [AudioUnitGraph<ManagedAudioUnitInstance>.Node] = []) {
            self.name = name
            self.instrument = instrument
            self._inserts = inserts
            self._headNode = self.findHeadNode()
        }
        
        init(graph: AudioUnitGraph<ManagedAudioUnitInstance>, snapshot: AudioSystemModel.ChannelModel) throws {
            self.name = snapshot.name
            self.instrument = try snapshot.instrument.map {
                try AudioUnitGraph.Node(graph: graph, presetData: $0)
            }
            self._inserts = try snapshot.inserts.map {
                try AudioUnitGraph.Node(graph: graph, presetData: $0)
            }
            self._headNode = self.findHeadNode()
            
            self.gain = snapshot.gain
            self.pan = snapshot.pan
        }
        
        func loadInstrument(fromDescription description: AudioComponentDescription) throws {
            self.instrument = try self.audioSystem?.graph.addNode(withDescription: description)
        }
        
        func addInsert(fromDescription description: AudioComponentDescription) throws {
            try self.audioSystem?.stopGraph()
            
            guard let insert = try self.audioSystem?.graph.addNode(withDescription: description) else { return }
            try self.add(insert: insert)
            try self.audioSystem?.startGraph()
            
        }
        
        var gain: AudioUnitParameterValue {
            get { return self.audioSystem.flatMap { try? $0.getGain(forChannelIndex: self.index) } ?? Float32.nan }
            set(v) { try? self.audioSystem?.setGain(forChannelIndex: self.index, to: v) }
        }
        var pan: AudioUnitParameterValue {
            get { return self.audioSystem.flatMap { try? $0.getPan(forChannelIndex: self.index) }.map { ($0*2.0)-1.0 } ?? Float32.nan }
            set(v) { try? self.audioSystem?.setPan(forChannelIndex: self.index, to: (v+1.0)*0.5) }
        }
        
        func snapshot() throws -> AudioSystemModel.ChannelModel {
            let instPresetData = try self.instrument?.getPresetData()
            return AudioSystemModel.ChannelModel(name: self.name, gain: self.gain, pan: self.pan, instrument: instPresetData, inserts: try self.inserts.map { try $0.getPresetData() })
        }
    }
    
}
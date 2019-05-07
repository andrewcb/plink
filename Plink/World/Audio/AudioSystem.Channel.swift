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
        
        /// An address of a component of the Channel
        enum Address {
            case instrument
            case insert(Int)
        }
        
        var name: String {
            didSet {
                self.audioSystem?.channelsChanged()
            }
        }
        // A link to the AudioSystem this Channel is part of; this is set when it is added, and is guaranteed to be
        // present while the Channel is in operation. It will be nil when a newly-created Channel has not been added yet.
        var audioSystem: AudioSystem? = nil
        var index: Int = -1
        var instrument: AudioUnitGraph<ManagedAudioUnitInstance>.Node? = nil {
            didSet(prev) {
                guard prev != self.instrument else { return }
                do {
                    try self.audioSystem!.modifyingGraph(reinit:false) {
                        try prev?.disconnectAll()
                        try prev?.removeFromGraph()
                        if let firstInsert = inserts.first {
                            try self.instrument?.connect(to: firstInsert)
                        }
                        self._headNode = self.findHeadNode()
                    }
                } catch {
                    fatalError("failed to disconnect/connect nodes: \(error)")
                }
            }
        }
        var _inserts: [AudioUnitGraph<ManagedAudioUnitInstance>.Node] = []
        var inserts: [AudioUnitGraph<ManagedAudioUnitInstance>.Node] {
            return self._inserts
        }
        
        func node(forAddress address: Address) -> AudioUnitGraph<ManagedAudioUnitInstance>.Node?  {
            switch(address) {
            case .instrument: return self.instrument
            case .insert(let index):
                return (index < self.inserts.count) ? self.inserts[index] : nil
            }
        }
        
        // methods for manipulating inserts
        func add(insert: AudioUnitGraph<ManagedAudioUnitInstance>.Node) throws {
            let lastHead = self.headNode
            self._inserts.append(insert)
            try self.audioSystem!.modifyingGraph(reinit:false) {
                try lastHead?.disconnectOutput()
                try lastHead?.connect(to: insert)
                self._headNode = self.findHeadNode()
            }
        }
        
        func replaceInsert(atIndex index: Int, with insert: AudioUnitGraph<ManagedAudioUnitInstance>.Node) throws {
            let target = self._inserts[index]
            let prev = (index==0) ? self.instrument : self._inserts[index-1]
            let next = (index<self._inserts.count-1) ? self._inserts[index+1] : nil
            try self.audioSystem!.modifyingGraph(reinit:false) {
                try prev?.disconnectOutput()
                try target.disconnectOutput()
                self._inserts[index] = insert
                try prev?.connect(to: insert)
                if let next = next {
                    try insert.connect(to: next)
                } else {
                    self._headNode = self.findHeadNode()
                }
            }
        }
        
        func removeInsert(atIndex index: Int) throws {
            guard index<self._inserts.count else { return }
            let isLast = index == self._inserts.count-1
            let target = self._inserts[index]
            let prev = (index==0) ? self.instrument : self._inserts[index-1]
            try self.audioSystem!.modifyingGraph {
                try prev?.disconnectOutput()
                try target.disconnectOutput()
                self._inserts.remove(at: index)
                if isLast {
                    self._headNode = self.findHeadNode()
                } else {
                    try prev?.connect(to: self._inserts[index])
                }
            }
        }
        
        /// The node that's at the end of the chain
        var _headNode: AudioUnitGraph<ManagedAudioUnitInstance>.Node? {
            didSet(prev) {
                guard self._headNode != prev else { return }
                self.onHeadNodeChanged?(self, prev)
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
            if !self._inserts.isEmpty {
                try graph.stop()
                try graph.uninitialize()
                try self.instrument!.connect(to: self._inserts.first!)
                try zip(self._inserts, self._inserts.dropFirst()).forEach { (a, b) in
                    try a.connect(to: b)
                }
                try graph.initialize()
                try graph.start()
            }
            
            self._headNode = self.findHeadNode()
            
            self.gain = snapshot.gain
            self.pan = snapshot.pan
        }
        
        func loadInstrument(fromDescription description: AudioComponentDescription) throws {
            self.instrument = try self.audioSystem?.graph.addNode(withDescription: description)
        }
        
        func addInsert(fromDescription description: AudioComponentDescription) throws {
            try self.audioSystem!.modifyingGraph(reinit:false) {
            
                guard let insert = try self.audioSystem?.graph.addNode(withDescription: description) else { return }
                try self.add(insert: insert)
            }
        }
        
        func replaceInsert(atIndex index: Int, usingDescription description: AudioComponentDescription) throws {
            try self.audioSystem!.modifyingGraph(reinit:false) {
                guard let insert = try self.audioSystem?.graph.addNode(withDescription: description) else { return }
                try self.replaceInsert(atIndex: index, with: insert)
            }
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

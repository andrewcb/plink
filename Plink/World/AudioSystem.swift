//
//  AudioSystem.swift
//  Plink
//
//  Created by acb on 07/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation
import AudioToolbox

class AudioSystem {
    let graph: AudioUnitGraph
    let mixerNode: AudioUnitGraph.Node
    let outNode: AudioUnitGraph.Node
    
    /// A Channel, currently consisting of an instrument and some inserts
    class Channel {
        var name: String
        var audioSystem: AudioSystem? = nil
        var index: Int = -1
        var instrument: AudioUnitGraph.Node? = nil {
            didSet(prev) {
                guard prev != self.instrument else { return }
                do {
                    try self.audioSystem?.graph.stop()
                    try prev?.disconnectAll()
                    try prev?.removeFromGraph()
                    if let firstInsert = inserts.first {
                        try self.instrument?.connect(to: firstInsert)
                    }
                    self._headNode = self.findHeadNode()
                    try self.audioSystem?.graph.start()
                } catch {
                    fatalError("failed to disconnect/connect nodes: \(error)")
                }
            }
        }
        var _inserts: [AudioUnitGraph.Node] = []
        var inserts: [AudioUnitGraph.Node] {
            return self._inserts
        }
        // methods for adding inserts
        func add(insert: AudioUnitGraph.Node) throws {
            let lastHead = self.headNode
            self._inserts.append(insert)
            try self.audioSystem?.graph.stop()
            try lastHead?.disconnectOutput()
            try lastHead?.connect(to: insert)
            self._headNode = self.findHeadNode()
            try self.audioSystem?.graph.start()
            
        }
        
        /// The node that's at the end of the chain
        var _headNode: AudioUnitGraph.Node? {
            didSet(prev) {
                self.onHeadNodeChanged?(self, prev)
            }
        }
        var headNode: AudioUnitGraph.Node? {
            return self._headNode
        }
        private func findHeadNode() -> AudioUnitGraph.Node? {
            return self.inserts.last ?? self.instrument
        }
        
        // notification method; called with the Channel and
        var onHeadNodeChanged: ((Channel,AudioUnitGraph.Node?)->())? = nil
        
        init(name: String, instrument: AudioUnitGraph.Node? = nil, inserts: [AudioUnitGraph.Node] = []) {
            self.name = name
            self.instrument = instrument
            self._inserts = inserts
            self._headNode = self.findHeadNode()
        }
        
        init(graph: AudioUnitGraph, snapshot: AudioSystemModel.ChannelModel) throws {
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
            //            print("Instrument loaded")
            audioSystem!.graph.dump()
        }
        
        func addInsert(fromDescription description: AudioComponentDescription) throws {
            try self.audioSystem?.graph.stop()
            
            guard let insert = try self.audioSystem?.graph.addNode(withDescription: description) else { return }
            try self.add(insert: insert)
            //            print("Insert loaded")
            //            audioSystem!.graph.dump()
            try self.audioSystem?.graph.start()
            
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
    
    var channels: [Channel] = []
    
    init() throws {
        self.graph = try AudioUnitGraph()
        self.mixerNode = try self.graph.addNode(withDescription: .stereoMixer)
        self.outNode = try self.graph.addNode(withDescription: .defaultOutput)
        try self.mixerNode.connect(to: self.outNode)
        try graph.open()
    }
    
    private func modifyingGraph(_ actions: (() throws ->())) throws {
        try graph.stop()
        try actions()
        // is this the best way?
        //        try graph.uninitialize()
        try graph.initialize()
        try graph.start()
    }
    
    func clear() throws {
        try self.modifyingGraph {
            for ch in self.channels {
                for insert in ch._inserts {
                    try insert.disconnectAll()
                    try insert.removeFromGraph()
                }
                try ch.instrument?.disconnectAll()
                try ch.instrument?.removeFromGraph()
            }
            self.channels = []
        }
    }
    
    /// add a Channel
    
    func add(channel: Channel) throws {
        let index = self.channels.count
        try self.modifyingGraph {
            try channel.headNode?.connect(element: 0, to: self.mixerNode, destElement: UInt32(index))
            channel.onHeadNodeChanged = { (_, _) in
                do {
                    try channel.headNode?.connect(element: 0, to: self.mixerNode, destElement: UInt32(index))
                } catch {
                    fatalError("Failed to reconnect head node: \(error)")
                }
            }
            self.channels.append(channel)
            channel.audioSystem = self
            channel.index = index
        }
        
    }
    
    /// Create a new Channel, with a default name and no inserts/instrument
    @discardableResult func createChannel() throws -> Channel {
        let channel = Channel(name: "ch\(self.channels.count+1)")
        try self.add(channel: channel)
        return channel
    }
    
    /// Look up a channel by name
    func channelNamed(_ name: String) -> Channel? {
        return self.channels.first(where: { $0.name == name })
    }
    
    //MARK: internal functions called from the channel
    fileprivate func getGain(forChannelIndex index: Int) throws -> AudioUnitParameterValue {
        return try self.mixerNode.getInstance().getParameterValue(0, scope: kAudioUnitScope_Input, element: AudioUnitElement(index))
    }
    fileprivate func getPan(forChannelIndex index: Int) throws -> AudioUnitParameterValue {
        return try self.mixerNode.getInstance().getParameterValue(1, scope: kAudioUnitScope_Input, element: AudioUnitElement(index))
    }
    fileprivate func setGain(forChannelIndex index: Int, to value: AudioUnitParameterValue) throws {
        return try self.mixerNode.getInstance().setParameterValue(0, scope: kAudioUnitScope_Input, element: AudioUnitElement(index), to: value)
    }
    fileprivate func setPan(forChannelIndex index: Int, to value: AudioUnitParameterValue) throws {
        return try self.mixerNode.getInstance().setParameterValue(1, scope: kAudioUnitScope_Input, element: AudioUnitElement(index), to: value)
    }
    
    //MARK: save/restore
    
    func snapshot() throws -> AudioSystemModel {
        return AudioSystemModel(channels: try self.channels.map { try $0.snapshot() })
    }
    
    func set(from snapshot: AudioSystemModel) throws {
        try self.clear()
        for ch in snapshot.channels {
            try self.add(channel: try Channel(graph: self.graph, snapshot: ch))
        }
    }
    
}

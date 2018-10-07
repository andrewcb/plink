//
//  AudioUnitGraph.swift
//  Plink
//
//  Created by acb on 07/12/2017.
//  Copyright © 2017 acb. All rights reserved.
//

import Foundation
import AudioToolbox
import CoreAudio

// Slightly less minimal Swiftifications

extension AUNode {
    init(graph: AUGraph, description: AudioComponentDescription) throws {
        self.init()
        var cd = description
        let status = AUGraphAddNode(graph, &cd, &self)
        if status != noErr {
            throw NSError(osstatus:status)
        }

    }
}

public class AudioUnitGraph {
    public var auRef: AUGraph
    
    /// An action to perform when opening the Graph (and loading AudioUnit Instances); this should set up each instance as needed
    var onOpen: (()->())?
    
    // An encapsulation of a graph node and the component it refers to
    public class Node {
        var graph: AudioUnitGraph?
        let node: AUNode
        var _audioUnit: AudioUnitInstance? = nil
        // (output)->(node,input) pairs that this node is connected to
        var _destinations: [UInt32:(Node, UInt32)] = [:]
        var _sources: [UInt32:(Node, UInt32)] = [:]
        
        enum Error: Swift.Error {
            case noGraph
        }

        public init(graph: AudioUnitGraph, description: AudioComponentDescription) throws {
            self.graph = graph
            self.node = try AUNode(graph: graph.auRef, description: description)
        }
        
        deinit {
            if let graph = self.graph { AUGraphRemoveNode(graph.auRef, self.node) }
        }
        
        convenience init(graph: AudioUnitGraph, preset: AudioUnitPreset) throws {
            try self.init(graph: graph, description: preset.audioComponentDescription)
            try self.getInstance().setClassInfo(fromDict: preset.propertyList as CFDictionary)
        }
        
        convenience init(graph: AudioUnitGraph, presetData: Data) throws {
            try self.init(graph: graph, preset: try AudioUnitPreset(data: presetData))
        }
        
        public func getInstance() throws -> AudioUnitInstance {
            guard let graph = self.graph else { throw Error.noGraph }

            if self._audioUnit == nil {
                self._audioUnit = try graph.getAudioUnit(for: self.node)
            }
            return self._audioUnit!
        }
        
        public func getInteractions() throws -> [AUNodeInteraction] {
            guard let graph = self.graph else { throw Error.noGraph }
            var count: UInt32 = 0
            let status0 = AUGraphCountNodeInteractions(graph.auRef, self.node, &count)
            if status0 != noErr { throw NSError(osstatus: status0)}

            var mem = UnsafeMutableBufferPointer<AUNodeInteraction>.allocate(capacity: Int(count))
            defer { mem.deallocate() }
            let status1 = AUGraphGetNodeInteractions(
                graph.auRef, self.node, &count,
                mem.baseAddress!
            )
            if status1 != noErr { throw NSError(osstatus: status1)}
            return mem.map { $0 }
        }
        
        public func connect(element: UInt32 = 0, to destNode: Node, destElement: UInt32 = 0) throws {
            guard let graph = self.graph else { return }
            try graph.connect(node: self.node, element: element, toNode: destNode.node, element: destElement)
            self._destinations[element]=(destNode, destElement)
            destNode._sources[destElement] = (self, element)
        }
        
        public func disconnectInput(element: UInt32 = 0) throws {
            guard let graph = self.graph else { return }
            try graph.disconnect(node: self.node, element: element)
            if let (snode, sout) = self._sources[element] {
                snode._destinations.removeValue(forKey: sout)
            }
            self._sources.removeValue(forKey: element)
        }
        
        public func disconnectOutput(element: UInt32 = 0) throws {
            guard self.graph != nil else { return }
            guard let (dnode, din) = self._destinations[element] else { return }
            try dnode.disconnectInput(element: din)
        }
        
        public func disconnectAllInputs() throws {
            for (input, _) in self._sources {
                try self.disconnectInput(element: input)
            }
        }

        public func disconnectAllOutputs() throws {
            for (output, _) in self._destinations {
                try self.disconnectOutput(element: output)
            }
        }
        
        public func disconnectAll() throws {
            try self.disconnectAllInputs()
            try self.disconnectAllOutputs()
        }
        
        public func removeFromGraph() throws {
            guard let graph = self.graph else { return }
            try graph.remove(node: self.node)
            self.graph = nil
        }
        
        func getPreset() throws -> AudioUnitPreset {
            let inst = try self.getInstance()
            return try ((inst.getClassInfo() as? [String:Any]).map { try AudioUnitPreset(propertyList: $0) }) ?? AudioUnitPreset.makeWithComponentOnly(from: inst.getAudioUnitComponent()!.audioComponentDescription)
        }
        
        func getPresetData() throws -> Data {
            return try (try self.getPreset()).asData()
        }

    }
    
    public init() throws {
        var maybeResult: AUGraph?
        let status = NewAUGraph(&maybeResult)
        guard let result = maybeResult else { throw NSError(osstatus:status) }
        self.auRef = result
    }
    
    deinit {
        if ((try? self.isRunning()).flatMap { $0 } ?? false) { try? self.stop() }
        if ((try? self.isInitialised()).flatMap { $0 } ?? false) { try? self.uninitialize() }
    }
    
    public func _addNode(withDescription description: AudioComponentDescription) throws -> AUNode {
        return try AUNode(graph: self.auRef, description: description)
    }
    
    public func _addNode(withType type: OSType, subType: OSType, manufacturer: OSType) throws -> AUNode {
        return try self._addNode(withDescription:AudioComponentDescription(
            componentType: type,
            componentSubType: subType,
            componentManufacturer: manufacturer,
            componentFlags: 0,componentFlagsMask: 0))
    }
    
    public func addNode(withDescription description: AudioComponentDescription) throws -> Node {
        return try Node(graph: self, description: description)
    }
    
    public func addNode(withType type: OSType, subType: OSType, manufacturer: OSType) throws -> Node {
        return try self.addNode(withDescription:AudioComponentDescription(
            componentType: type,
            componentSubType: subType,
            componentManufacturer: manufacturer,
            componentFlags: 0,componentFlagsMask: 0))
    }

    
    public func _addNode(withPreset preset: AudioUnitPreset) throws -> AUNode {
        let node = try self._addNode(withDescription: preset.audioComponentDescription)
        if try self.isOpen() {
            try (try? self.getAudioUnit(for: node))?.setClassInfo(fromDict: preset.propertyList as NSDictionary as CFDictionary)
        }
        // this is added to onOpen, in case the graph is closed and opened again
        let prev = self.onOpen
        self.onOpen = {
            try? (try? self.getAudioUnit(for: node))?.setClassInfo(fromDict: preset.propertyList as NSDictionary as CFDictionary)
            prev?()
        }
        return node
    }
    
    public func addNode(withPreset preset: AudioUnitPreset) throws -> Node {
        let node = try self.addNode(withDescription: preset.audioComponentDescription)
        if try self.isOpen() {
            try node.getInstance().setClassInfo(fromDict: preset.propertyList as NSDictionary as CFDictionary)
        } else {
            let prev = self.onOpen
            self.onOpen = {
                try? (try? node.getInstance())?.setClassInfo(fromDict: preset.propertyList as NSDictionary as CFDictionary)
                prev?()
            }
            return node

        }
        return node
    }

    
    public func remove(node: AUNode) throws {
        let status = AUGraphRemoveNode(self.auRef, node)
        if status != noErr { throw NSError(osstatus:status) }
    }
    
    public func getNodeCount() throws -> Int {
        var count: UInt32 = 0
        let status = AUGraphGetNodeCount(self.auRef, &count)
        if status != noErr { throw NSError(osstatus: status)}
        return Int(count)
    }
    
    public func getInteractionCount() throws -> Int {
        var count: UInt32 = 0
        let status = AUGraphGetNumberOfInteractions(self.auRef, &count)
        if status != noErr { throw NSError(osstatus: status)}
        return Int(count)
    }
    
    public func getNodeIDs() throws -> [AUNode] {
        return try (0..<UInt32(try self.getNodeCount())).map { index in
            var node = AUNode(0)
            let status = AUGraphGetIndNode(self.auRef, index, &node)
            if status != noErr { throw NSError(osstatus: status) }
            return node
        }
    }
    
    public func getNodeInteractions() throws -> [AUNodeInteraction] {
        let count = UInt32(try self.getInteractionCount())
        return try (0..<count).map { index in
            var interaction = AUNodeInteraction(nodeInteractionType: 0, nodeInteraction: AUNodeInteraction.__Unnamed_union_nodeInteraction(connection: AUNodeConnection(sourceNode: 0, sourceOutputNumber: 0, destNode: 0, destInputNumber: 0)))
            let status = AUGraphGetInteractionInfo(self.auRef, index, &interaction)
            if status != noErr { throw NSError(osstatus: status) }
            return interaction

        }
    }
    
    public func open() throws {
        let status = AUGraphOpen(self.auRef)
        if status != noErr { throw NSError(osstatus:status) }
        self.onOpen?()
    }
    
    public func close() throws {
        let status = AUGraphClose(self.auRef)
        if status != noErr { throw NSError(osstatus:status) }
    }
    
    public func isOpen() throws -> Bool {
        var result: DarwinBoolean = false
        let status = AUGraphIsOpen(self.auRef, &result)
        if status != noErr { throw NSError(osstatus: status) }
        return result.boolValue
    }
    
    private func getAURef(for node: AUNode) throws -> AudioUnit {
        var maybeUnit: AudioUnit? = nil
        let status = AUGraphNodeInfo(self.auRef, node, nil, &maybeUnit)
        guard let unit = maybeUnit else { throw NSError(osstatus:status) }
        return unit
    }
    
    public func getAudioUnit(for node: AUNode) throws -> AudioUnitInstance {
        return AudioUnitInstance(auRef: try self.getAURef(for: node))
    }
    
    public func connect(node fromNode: AUNode, element fromElement: AudioUnitElement, toNode: AUNode, element toElement: AudioUnitElement) throws {
        let status = AUGraphConnectNodeInput(self.auRef, fromNode, fromElement, toNode, toElement)
        if status != noErr { throw NSError(osstatus:status) }
    }
    
    public func disconnect(node destNode: AUNode, element: AudioUnitElement) throws {
        let status = AUGraphDisconnectNodeInput(self.auRef, destNode, element)
        if status != noErr { throw NSError(osstatus:status) }
    }
    
    public func initialize() throws {
        let status = AUGraphInitialize(self.auRef)
        if status != noErr { throw NSError(osstatus:status) }
    }
    
    public func uninitialize() throws {
        let status = AUGraphUninitialize(self.auRef)
        if status != noErr { throw NSError(osstatus:status) }
    }
    
    public func start() throws {
        let status = AUGraphStart(self.auRef)
        if status != noErr { throw NSError(osstatus:status) }
    }
    
    public func stop() throws {
        let status = AUGraphStop(self.auRef)
        if status != noErr { throw NSError(osstatus:status) }
    }
    
    public func isInitialised() throws -> Bool {
        var result = DarwinBoolean(false)
        let status = AUGraphIsInitialized(self.auRef, &result)
        if status != noErr { throw NSError(osstatus:status) }
        return result.boolValue
    }
    
    public func isRunning() throws -> Bool {
        var result = DarwinBoolean(false)
        let status = AUGraphIsRunning(self.auRef, &result)
        if status != noErr { throw NSError(osstatus:status) }
        return result.boolValue
    }
}

extension AudioUnitGraph.Node: Equatable {
    public static func ==(lhs: AudioUnitGraph.Node, rhs: AudioUnitGraph.Node) -> Bool {
        return (lhs.graph?.auRef == rhs.graph?.auRef) && (lhs.node == rhs.node)
    }
}

extension AudioUnitGraph.Node: CustomStringConvertible {
    public var description: String {
        return "<Node \(self.node)>"
    }
}

extension AudioUnitGraph.Node {
    public func hasConnection(matching predicate: ((AUNodeConnection)->Bool)) throws -> Bool {
        let conns = try self.getInteractions().filter { $0.nodeInteractionType == kAUNodeInteraction_Connection }
        return conns.contains(where: { predicate($0.nodeInteraction.connection) })

    }
    
    public func isConnected(to dest: AudioUnitGraph.Node) throws -> Bool {
        return try self.hasConnection(matching: { $0.destNode == dest.node })
    }
    
    public func isConnected(to dest: AudioUnitGraph.Node, input: UInt32) throws -> Bool {
        return try self.hasConnection(matching: { $0.destNode == dest.node && $0.destInputNumber == input })
    }
}

extension AudioUnitGraph {
    func dump() {
        do {
            print("Graph has nodes: \(try self.getNodeIDs())")
            for interaction in try self.getNodeInteractions() {
                if interaction.nodeInteractionType == kAUNodeInteraction_Connection {
                    let conn = interaction.nodeInteraction.connection
                    print("\(conn.sourceNode):\(conn.sourceOutputNumber) => \(conn.destNode):\(conn.destInputNumber)")
                }
            }
        } catch {
            print("graph dump failed: \(error)")
        }
    }

}

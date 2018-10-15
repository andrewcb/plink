//
//  ManagedAudioUnitInstance.swift
//  Plink
//
//  Created by acb on 14/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

/** A wrapper around an AudioUnitInstanceBase, adding some stateful management; i.e., this keeps track of the instance's parameter values and sends notifications if they change */

public class ManagedAudioUnitInstance {
    let instance: AudioUnitInstanceBase
    
    typealias ParameterValueListener = ((ManagedAudioUnitInstance, AudioUnitParameterID, AudioUnitScope, AudioUnitElement, AudioUnitParameterValue)->())
    
    var parameterValueListenerRegistry = ConnectionRegistry<ParameterValueListener>()
    func addParameterValueListener(_ listener: @escaping ParameterValueListener) -> ConnectionRegistry<Any>.Id {
        return self.parameterValueListenerRegistry.add(connection: listener)
    }
    func removeParameterValueListener(withID id: ConnectionRegistry<Any>.Id) {
        self.parameterValueListenerRegistry.removeConnection(withId: id)
    }
    
    private var _parameterInfo: [AudioUnitScope:[AudioUnitInstanceBase.ParameterInfo]] = [:]
    
    init(instance: AudioUnitInstanceBase) {
        self.instance = instance
    }
    
    public func getAudioUnitComponent() -> AudioUnitComponent? {
        return self.instance.getAudioUnitComponent()
    }
    
    public func loadInterfaceView(withSize size: CGSize) -> NSView? {
        return loadInterfaceViewForAudioUnit(self.instance.auRef, size)
    }
    
    public func allParameterInfo(forScope scope: AudioUnitScope) -> [AudioUnitInstanceBase.ParameterInfo] {
        if self._parameterInfo[scope] == nil {
            do {
                self._parameterInfo[scope] = try self.instance.getAllParameterInfo(forScope: scope)
            } catch {
                print("Error in getAllParameterInfo(forScope:\(scope)): \(error)")
            }
        }
        return self._parameterInfo[scope] ?? []
    }
    
    
    public func getParameterValue(_ id: AudioUnitParameterID, scope: AudioUnitScope, element: AudioUnitElement) throws -> AudioUnitParameterValue {
        return try self.instance.getParameterValue(id,scope:scope,element:element)
    }
    
    public func setParameterValue(_ id: AudioUnitParameterID, scope: AudioUnitScope, element: AudioUnitElement, to value: AudioUnitParameterValue) throws {
        try self.instance.setParameterValue(id, scope: scope, element: element, to: value)
        self.parameterValueListenerRegistry.connections.forEach {
            $0(self, id, scope, element, value)
        }
        
    }
    
    public func render(withFlags flags: AudioUnitRenderActionFlags = [], timeStamp: AudioTimeStamp, outputBusNumber: UInt32 = 0, numberOfFrames: UInt32, data: inout AudioBufferList) throws {
        try self.instance.render(withFlags:flags, timeStamp: timeStamp, outputBusNumber: outputBusNumber, numberOfFrames:numberOfFrames, data:&data)
    }
    
    public func sendMIDIEvent(_ statusByte: UInt8, _ data1: UInt8, _ data2: UInt8, atSampleOffset offset: UInt32) throws {
        try self.instance.sendMIDIEvent(statusByte, data1, data2, atSampleOffset:offset)
        
    }
    
    public func getClassInfo() throws -> CFDictionary? {
        return try self.instance.getClassInfo()
    }
    
    public func setClassInfo(fromDict dict: CFDictionary) throws {
        try self.instance.setClassInfo(fromDict: dict)
    }

    public func setRenderCallback(_ callback: @escaping AURenderCallback) {
        self.instance.setRenderCallback(callback)
    }
}

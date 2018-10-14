//
//  AudioUnitInstanceBase.swift
//  Plink
//
//  Created by acb on 07/12/2017.
//  Copyright © 2017 acb. All rights reserved.
//

import Foundation
import AudioToolbox
import CoreAudio

// A basic no-frills encapsulation of an AudioUnit. Internally, this is weakly typed, and, say, attempting to send MIDI to a non-instrument will probably cause a runtime error, but this is a very thin wrapper.
public struct AudioUnitInstanceBase {
    public var auRef: AudioUnit
    
    // A struct to encapsulate the specs of a parameter in a more modern fashion
    public struct ParameterInfo {
        public let id: AudioUnitParameterID
        public let name: String?
        public let unit: AudioUnitParameterUnit
        public let range: ClosedRange<AudioUnitParameterValue>
        public let defaultValue: AudioUnitParameterValue
        public let flags: AudioUnitParameterOptions
        
        init(id: AudioUnitParameterID, info: AudioUnitParameterInfo) {
            self.id = id
            self.name = (info.cfNameString?.takeUnretainedValue()).map { $0 as String }
            self.unit = info.unit
            self.range = (info.minValue...info.maxValue)
            self.defaultValue = info.defaultValue
            self.flags = info.flags
        }
    }
    
    public func getAudioUnitComponent() -> AudioUnitComponent? {
        let component = AudioComponentInstanceGetComponent(self.auRef)
        if component == OpaquePointer(bitPattern: 0) { return nil }
        return AudioUnitComponent(component: component)
    }
    
    public func getPropertyInfo(withID id: AudioUnitPropertyID, scope: AudioUnitScope, element: AudioUnitElement) -> (size: UInt32, writable: Bool) {
        var size: UInt32 = 0
        var writable: DarwinBoolean = false
        AudioUnitGetPropertyInfo(auRef, id, scope, element, &size, &writable)
        return (size, writable.boolValue)
    }
    
    public func getProperty(withID id: AudioUnitPropertyID, scope: AudioUnitScope, element: AudioUnitElement, data: UnsafeMutableRawPointer, dataSize: UnsafeMutablePointer<UInt32>) throws {
        let status = AudioUnitGetProperty(auRef, id, scope, element, data, dataSize)
        if status != noErr { throw NSError(osstatus:status)}
    }
    
    public func getProperty<T>(withID id: AudioUnitPropertyID, scope: AudioUnitScope, element: AudioUnitElement) throws -> T {
        var resultSize = UInt32(MemoryLayout<T>.size)
        var mem = UnsafeMutablePointer<T>.allocate(capacity:1)
        defer { mem.deallocate() }
        try self.getProperty(withID: id, scope: scope, element: element, data: mem, dataSize: &resultSize)
        return mem.pointee
    }
    
    public func getPropertyArray<T>(withID id: AudioUnitPropertyID, scope: AudioUnitScope, element: AudioUnitElement) throws -> [T] {
        let (size, _) = self.getPropertyInfo(withID: id, scope: scope, element: element)
        let sizeOfOne = MemoryLayout<T>.size
        let count = Int(size) / sizeOfOne
        var resultSize = UInt32(sizeOfOne*count)
        var mem = UnsafeMutableBufferPointer<T>.allocate(capacity: count)
        defer { mem.deallocate() }
        try self.getProperty(withID: id, scope: scope, element: element, data: UnsafeMutableRawPointer(mem.baseAddress!), dataSize: &resultSize)
        return mem.map { $0 }
    }
    
    public func setProperty(withID id: AudioUnitPropertyID, scope: AudioUnitScope, element: AudioUnitElement, data: UnsafeRawPointer?, dataSize: UInt32) throws {
        let status = AudioUnitSetProperty(auRef, id, scope, element, data, dataSize)
        if status != noErr { throw NSError(osstatus:status) }
    }
    
    public func setProperty<T>(withID id: AudioUnitPropertyID, scope: AudioUnitScope, element: AudioUnitElement, to value: T) throws {
        var valueVar = value
        try self.setProperty(withID: id, scope: scope, element: element, data: &valueVar, dataSize: UInt32(MemoryLayout<T>.size))
    }
    
    public func getAllParameterInfo(forScope scope: AudioUnitScope) throws -> [ParameterInfo] {
        let paramIDs: [AudioUnitParameterID] = try self.getPropertyArray(withID: kAudioUnitProperty_ParameterList, scope: scope, element: 0)
        var paramSize: UInt32 = self.getPropertyInfo(withID: kAudioUnitProperty_ParameterInfo, scope: scope, element: 0).0
        // getProperty<T> crashes on this for some reason; we need to make some ugly state here
        var parameterInfo = AudioUnitParameterInfo(name: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0), unitName: nil, clumpID: 0, cfNameString: nil, unit: AudioUnitParameterUnit.customUnit, minValue: 0.0, maxValue: 0.0, defaultValue: 0.0, flags: [])
        return try paramIDs.map { (id) -> ParameterInfo in
            try self.getProperty(withID: kAudioUnitProperty_ParameterInfo, scope: scope, element: id, data: &parameterInfo, dataSize: &paramSize)
            return ParameterInfo(id: id, info: parameterInfo)
        }
    }
    
    public func getParameterValue(_ id: AudioUnitParameterID, scope: AudioUnitScope, element: AudioUnitElement) throws -> AudioUnitParameterValue {
        var v: AudioUnitParameterValue = 0
        let status = AudioUnitGetParameter(auRef, id, scope, element, &v)
        if status != noErr { throw NSError(osstatus:status)}
        return v
    }
    
    public func setParameterValue(_ id: AudioUnitParameterID, scope: AudioUnitScope, element: AudioUnitElement, to value: AudioUnitParameterValue) throws {
        let status = AudioUnitSetParameter(auRef, id, scope, element, value, 0 /* FIXME */)
        if status != noErr { throw NSError(osstatus:status)}
    }
    
    public func render(withFlags flags: AudioUnitRenderActionFlags = [], timeStamp: AudioTimeStamp, outputBusNumber: UInt32 = 0, numberOfFrames: UInt32, data: inout AudioBufferList) throws {
        var flagsVar = flags
        var timeStampVar = timeStamp
        let status = AudioUnitRender(auRef, &flagsVar, &timeStampVar, outputBusNumber, numberOfFrames, &data)
        if status != noErr { throw NSError(osstatus:status) }
    }
    
    
    public func sendMIDIEvent(_ statusByte: UInt8, _ data1: UInt8, _ data2: UInt8, atSampleOffset offset: UInt32) throws {
        let status = MusicDeviceMIDIEvent(self.auRef, UInt32(statusByte), UInt32(data1), UInt32(data2), offset)
        if status != noErr { throw NSError(osstatus:status) }
    }
    
    public func getClassInfo() throws -> CFDictionary? {
        var classInfo:  CFDictionary = NSDictionary()
        var classInfoSize: UInt32 = UInt32(MemoryLayout<CFDictionary>.size)
        let status = AudioUnitGetProperty(self.auRef, kAudioUnitProperty_ClassInfo, kAudioUnitScope_Global, 0, &classInfo, &classInfoSize)
        if status != noErr { throw NSError(osstatus:status) }
        return classInfo
    }

    
    public func setClassInfo(fromDict dict: CFDictionary) throws {
        var classInfo = dict
        let classInfoSize: UInt32 = UInt32(MemoryLayout<CFDictionary>.size)
        let status = AudioUnitSetProperty(self.auRef, kAudioUnitProperty_ClassInfo, kAudioUnitScope_Global, 0, &classInfo, classInfoSize)
        if status != noErr { throw NSError(osstatus:status) }
    }
    
    public func setRenderCallback(_ callback: @escaping AURenderCallback) {
        var callback = callback
        let callbackSize = UInt32(MemoryLayout<AURenderCallback>.size)
        AudioUnitSetProperty(self.auRef, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Global, 0, &callback, callbackSize)
    }
    
}

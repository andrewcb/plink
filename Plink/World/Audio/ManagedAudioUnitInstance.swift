//
//  ManagedAudioUnitInstance.swift
//  Plink
//
//  Created by acb on 14/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

/** An enhanced type of AudioUnitInstance, adding some stateful management; i.e., this keeps track of the instance's parameter values and sends notifications if they change */

public class ManagedAudioUnitInstance: AudioUnitInstance {
    public var auRef: AudioUnit
    
    public var interfaceWindow: NSWindow? = nil
    
    required public init(auRef: AudioUnit) {
        self.auRef = auRef
    }

    typealias ParameterValueListener = ((ManagedAudioUnitInstance, AudioUnitParameterID, AudioUnitScope, AudioUnitElement, AudioUnitParameterValue)->())
    
    var parameterValueListenerRegistry = ConnectionRegistry<ParameterValueListener>()
    func addParameterValueListener(_ listener: @escaping ParameterValueListener) -> ConnectionRegistry<Any>.Id {
        return self.parameterValueListenerRegistry.add(connection: listener)
    }
    
    func removeParameterValueListener(withID id: ConnectionRegistry<Any>.Id) {
        self.parameterValueListenerRegistry.removeConnection(withId: id)
    }
    
    private var _parameterInfo: [AudioUnitScope:[AudioUnitInstanceParameterInfo]] = [:]
    
    public func loadInterfaceView(withSize size: CGSize) -> NSView? {
        return loadInterfaceViewForAudioUnit(self.auRef, size)
    }
    
    public func prepareForRemoval() {
        self.interfaceWindow?.close()
    }
    
    public func allParameterInfo(forScope scope: AudioUnitScope) -> [AudioUnitInstanceParameterInfo] {
        if self._parameterInfo[scope] == nil {
            do {
                self._parameterInfo[scope] = try self.getAllParameterInfo(forScope: scope)
            } catch {
                print("Error in getAllParameterInfo(forScope:\(scope)): \(error)")
            }
        }
        return self._parameterInfo[scope] ?? []
    }
    
    
    public func setParameterValue(_ id: AudioUnitParameterID, scope: AudioUnitScope, element: AudioUnitElement, to value: AudioUnitParameterValue) throws {
        try (self as AudioUnitInstance).setParameterValue(id, scope: scope, element: element, to: value)
        self.parameterValueListenerRegistry.connections.forEach {
            $0(self, id, scope, element, value)
        }
        
    }
    
    //MARK: MIDINote
    func play(MIDINote note: MIDINote, withMetronome metronome: Metronome, scheduler: Scheduler)  throws {
        let onTime = metronome.tickTime
        let offTime = onTime + note.duration
        try self.sendMIDIEvent(0x90 | note.channel, note.note, note.velocity, atSampleOffset: 0)
        // Should scheduler have a hold on the Metronome?
        scheduler.schedule(atMetronomeTime: offTime, action: { [weak self] () in
            // if Note On didn't throw, this probably won't
            try? self?.sendMIDIEvent(0x80 | note.channel, note.note, note.velocity, atSampleOffset: 0)
        }, executeOnClear: false)
    }
}

extension ManagedAudioUnitInstance: CustomStringConvertible {
    public var description: String {
        guard let component = self.getAudioUnitComponent() else { return "<AudioUnit: ?>" }
        return "<AudioUnit: \(component.componentName ?? "?") >"
    }
}

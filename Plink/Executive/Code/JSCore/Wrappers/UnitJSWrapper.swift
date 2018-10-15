//
//  Unit.swift
//  Plink
//
//  Created by acb on 07/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc protocol UnitExports: JSExport {
    func sendMIDIEvent(_ b1: Int, _ b2: Int, _ b3: Int)
    func getParam(_ name: String) -> JSValue
    func setParam(_ name: String, _ value: Float32) -> JSValue
}


extension JSCoreCodeEngine {

    @objc public class Unit: NSObject, UnitExports {
        var instance: ManagedAudioUnitInstance
        weak var engine: JSCoreCodeEngine!
        var paramNameMap: [String:AudioUnitParameterID]
        
        init(instance: ManagedAudioUnitInstance, engine: JSCoreCodeEngine) {
            self.instance = instance
            self.engine = engine
            let allParamInfo = instance.allParameterInfo(forScope: kAudioUnitScope_Global)
            self.paramNameMap = [String:AudioUnitParameterID](allParamInfo.compactMap { (info) in info.name.map { ($0, info.id) } }, uniquingKeysWith: { (old, new)  in old })
            super.init()
        }
        
        @objc func sendMIDIEvent(_ b1: Int, _ b2: Int, _ b3: Int) {
            try? self.instance.sendMIDIEvent(UInt8(b1 & 0xff), UInt8(b2 & 0x7f), UInt8(b2 & 0x7f), atSampleOffset: 0)
        }
        
        func getParam(_ name: String) -> JSValue {
            guard let paramId = self.paramNameMap[name] else {
                self.engine.delegate?.codeLanguageExceptionOccurred("Unit has no parameter named \(name)")
                return JSValue(undefinedIn: self.engine.ctx)
            }
            do {
                let val = try self.instance.getParameterValue(paramId, scope: kAudioUnitScope_Global, element: 0)
                return JSValue(double: Double(val), in: self.engine.ctx)
            }
            catch {
                self.engine.delegate?.codeLanguageExceptionOccurred("\(error)")
                return JSValue(undefinedIn: self.engine.ctx)
            }
        }
        
        func setParam(_ name: String, _ value: Float32) -> JSValue {
            guard
                let paramId = self.paramNameMap[name]
            else {
                self.engine.delegate?.codeLanguageExceptionOccurred("Unit has no parameter named \(name)")
                return JSValue(undefinedIn: self.engine.ctx)
            }
            do {
                try self.instance.setParameterValue(paramId, scope: kAudioUnitScope_Global, element: 0, to: value)
                return JSValue(double: Double(value), in: self.engine.ctx)
            } catch {
                self.engine.delegate?.codeLanguageExceptionOccurred("\(error)")
                return JSValue(undefinedIn: self.engine.ctx)
            }
        }


    }
}

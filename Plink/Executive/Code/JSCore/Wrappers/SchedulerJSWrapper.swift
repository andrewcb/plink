//
//  SchedulerJSWrapper.swift
//  Plink
//
//  Created by acb on 08/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc protocol SchedulerExports: JSExport {
    func everyTickMultiple(_ multiple: Int, _ block: JSValue)  -> JSValue
    func everyBeatFraction(_ num: Int, _ denom: Int, _ block: JSValue)  -> JSValue
    func atBeatTime(_ beat: Double, _ block: JSValue)  -> JSValue
    func atTickTime(_ tick: Int, _ block: JSValue)  -> JSValue
}

extension JSCoreCodeEngine {
    @objc public class Scheduler: NSObject, SchedulerExports {
        weak var scheduler: Plink.Scheduler!
        weak var engine: JSCoreCodeEngine!
        
        init(scheduler: Plink.Scheduler, engine: JSCoreCodeEngine) {
            self.scheduler = scheduler
            self.engine = engine
        }
        
        func everyTickMultiple(_ ticks: Int, _ block: JSValue) -> JSValue {
            return JSValue(int32: Int32(self.scheduler.createPeriodicAction(period: ticks) { (i, t) in
                block.call(withArguments: [i, t.value])
            }), in: block.context)
        }
        
        func everyBeatFraction(_ num: Int, _ denom: Int, _ block: JSValue) -> JSValue {
            let ticks = TickTime.ticksPerBeat * num / denom
            if ticks >= 1 {
                return self.everyTickMultiple(ticks, block)
            } else {
                self.engine.delegate?.codeLanguageExceptionOccurred("Beat fraction \(num)/\(denom) is too short; it must be 1/\(TickTime.ticksPerBeat) or longer")
                return JSValue(undefinedIn: block.context)
            }
        }
        
        func atBeatTime(_ beat: Double, _ block: JSValue) -> JSValue {
            return self.atTickTime(Int(beat*Double(TickTime.ticksPerBeat)), block)
        }
        
        func atTickTime(_ tick: Int, _ block: JSValue)  -> JSValue {
            return JSValue(int32: Int32(self.scheduler.createSingleAction(time: TickTime(tick), action: {block.call(withArguments: [])})), in: block.context)
        }
        
    }
}

//
//  Scheduler.swift
//  Plink
//
//  Created by acb on 30/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

class Scheduler {
    /// A periodic action, executed every cycle of `period` ticks
    struct PeriodicAction {
        let id: Int
        let period: Int
        /// execute on the nth tick of a period
        let modulus: Int
        let action: (Int, TickTime) -> Void
        let isEnabled: Bool
        
        func executeIfPermitted(at time: TickTime) {
            if self.isEnabled && time.value % self.period == self.modulus {
                self.action(time.value/self.period, time)
            }
        }
    }
    
    /// An action to be executed at a specific concrete time
    struct SingleAction {
        let id: Int
        let time: TickTime
        let action: (()->Void)
        let isEnabled: Bool
    }
    
    var periodicActions: [PeriodicAction] = []
    var nextActionID: Int = 0
    private func getNextActionID() -> Int {
        defer { self.nextActionID += 1 }
        return self.nextActionID
    }
    
    var singleActions: [Int:[SingleAction]] = [:]
    
    func createPeriodicAction(period: Int, modulus: Int = 0, isEnabled: Bool = true, action: @escaping ((Int, TickTime)->())) -> Int {
        let id = self.getNextActionID()
        self.periodicActions.append(Scheduler.PeriodicAction(id: id, period: period, modulus: modulus, action: action, isEnabled: isEnabled))
        return id
    }
    
    func createSingleAction(time: TickTime, isEnabled: Bool = true, action: @escaping (()->Void) ) -> Int {
        let id = self.getNextActionID()
        let ac = SingleAction(id: id, time: time, action: action, isEnabled: isEnabled)
        if self.singleActions[time.value] == nil {
            self.singleActions[time.value] = [ac]
        } else {
            self.singleActions[time.value]!.append(ac)
        }
        return id
    }
    
    func deleteAction(withID id: Int) {
        self.periodicActions = self.periodicActions.filter {
            $0.id != id
        }
        for (k, v) in self.singleActions {
            self.singleActions[k] = v.filter { $0.id != id }
        }
    }
    
    /// metronome scheduling; this is more low-level, not being exposed to the executive API, and is just a mapping of times to closures, with each removed as it is executed
    
    // TODO: make this an ordered linked list, for efficient lookup/removal
    struct MetronomeScheduled {
        /// The action to execute
        let action: (()->())
        /// When all future actions are cleared (i.e., if the audio setup is changed), do we execute this action before removing it?
        let executeOnClear: Bool
    }
    var metroAt: [TickTime: [MetronomeScheduled]] = [:]
    
    func schedule(atMetronomeTime time: TickTime, action: @escaping (()->()), executeOnClear: Bool = false) {
        // TODO: add locking here?
        metroAt[time] = (metroAt[time] ?? []) + [MetronomeScheduled(action: action, executeOnClear: executeOnClear)]
    }
    
    
    
    ///
    
    func clear() {
        self.singleActions = [:]
        self.periodicActions = []
    }

    /// Receive a running program time
    func runFor(time: TickTime) {
        let singles = singleActions[time.value] ?? []
        // FIXME: make a queue for the language environment
//        DispatchQueue.main.async {
            for action in self.periodicActions {
                action.executeIfPermitted(at: time)
            }
            
            for action in singles {
                action.action()
            }
//        }
    }
    
    func metronomeTick(_ time: TickTime) {
        for action in (metroAt[time] ?? []) {
            action.action()
        }
        metroAt[time] = nil
    }
    
    /// Clear all pending actions, executing the ones flagged as executeOnClear
    func clearPendingMetroActions() {
        for actions in metroAt.values {
            for action in actions {
                if action.executeOnClear {
                    action.action()
                }
            }
        }
        metroAt = [:]
    }
    
    /// MARK: blocking wait
    
    let sleepQueue = DispatchQueue(label: "Scheduler.sleep")
    func sleep(until time: TickTime) {
        let ds = DispatchSemaphore(value: 0)
        self.schedule(atMetronomeTime: time, action: {
            ds.signal()
        }, executeOnClear: true)
        sleepQueue.sync {
            ds.wait()
        }
    }
}

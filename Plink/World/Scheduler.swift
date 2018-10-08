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
    
    func clear() {
        self.singleActions = [:]
        self.periodicActions = []
    }
}

extension Scheduler: TransportClient {
    func runFor(time: TickTime) {
        for action in self.periodicActions {
            action.executeIfPermitted(at: time)
        }
        
        for action in singleActions[time.value] ?? [] {
            action.action()
        }
    }
}

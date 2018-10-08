//
//  CodeEngineEnvironment.swift
//  Plink
//
//  Created by acb on 14/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation

/** A structure for passing all the parts of the world the code is meant to be able to manipulate in one unit. The objects referred to in this structure are the actual system-facing objects; code engines will probably wrap these in translation layers**/

struct CodeEngineEnvironment {
    /// the audio system
    let audioSystem: AudioSystem?
    
    /// the transport: tempo, start/stop, and such, will go here
    let transport: Transport

    /// the scheduler: trigger functions at intervals/times
    let scheduler: Scheduler
}

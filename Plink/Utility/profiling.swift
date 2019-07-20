//
//  profiling.swift
//  Plink
//
//  Created by acb on 2019-07-17.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Foundation

let timebaseInfo: mach_timebase_info_data_t = {
    let p = UnsafeMutablePointer<mach_timebase_info_data_t>.allocate(capacity: 1)
    mach_timebase_info(p)
    let r = p.pointee
    defer { p.deallocate() }
//    print("***\ntimebase == \(r.numer)/\(r.denom)\n---")
    return r
}()

func convertToNanoseconds(fromMachTime machTime: UInt64) -> UInt64 {
    return  (machTime * UInt64(timebaseInfo.numer)) / UInt64(timebaseInfo.denom)
}

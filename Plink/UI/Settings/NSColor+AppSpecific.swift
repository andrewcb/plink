//
//  NSColor+AppSpecific.swift
//  Plink
//
//  Created by acb on 11/09/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

extension NSColor {
    static var mixerBackground = NSColor(deviceRed: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
    
    static var instrumentNode = NSColor(deviceHue: 0.5, saturation: 0.8, brightness: 1.0, alpha: 1.0)
    static var audioEffectNode = NSColor(deviceHue: 0.7, saturation: 0.5, brightness: 1.0, alpha: 1.0)
    
    static var codeBackground = NSColor(deviceHue: 0.0, saturation: 0.0, brightness: 0.1, alpha: 1.0)
    static var scrollbackBackground = NSColor(deviceHue: 0.0, saturation: 0.0, brightness: 0.125, alpha: 1.0)
    static var codeRegularText = NSColor(deviceHue: 0.6, saturation: 0.2, brightness: 0.9, alpha: 1.0)
    static var codeEchoText = NSColor(deviceHue: 0.8, saturation: 0.2, brightness: 0.5, alpha: 1.0)
    static var codeErrorText = NSColor(deviceHue: 0.0, saturation: 0.9, brightness: 0.8, alpha: 1.0)
    static var scrollbackRestoredText = NSColor(deviceHue: 0.8, saturation: 0.0, brightness: 0.5, alpha: 1.0)
}

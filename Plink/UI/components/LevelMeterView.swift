//
//  LevelMeterView.swift
//  Plink
//
//  Created by acb on 25/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa
import AudioToolbox

class LevelMeterView: NSView {
    enum Orientation {
        case vertical
        case horizontal
    }
    
    var orientation: Orientation = .vertical
    var levelReading: AudioSystem.StereoLevelReading? {
        didSet {
            self._normalisedLevels = self.levelReading.map {
                $0.map { (LevelMeterView.levelToProportion($0.average), LevelMeterView.levelToProportion($0.peak))  } }
            
        }
    }
    
    static let minimum: AudioUnitParameterValue = -120.0
    static let maximum: AudioUnitParameterValue = 0.0

    private static func levelToProportion(_ level: AudioUnitParameterValue) -> CGFloat {
        return CGFloat((level - minimum) / (maximum-minimum))
    }

    private var _normalisedLevels: StereoPair<(CGFloat, CGFloat)>? {
        didSet {
            // TODO: partial invalidation/redrawing?
            self.needsDisplay = true
        }
    }
    
    // logical coördinates, with respect to the current orientation
    var logicalLength: CGFloat { return self.orientation == .vertical ? self.bounds.height : self.bounds.width }
    var logicalBreadth: CGFloat { return self.orientation == .horizontal ? self.bounds.height : self.bounds.width }
    
    let gradient = NSGradient(colors: [NSColor.green, NSColor.yellow, NSColor.red], atLocations: [0.0, 0.75, 1.0], colorSpace: NSColorSpace.deviceRGB)!
    
    override func draw(_ dirtyRect: NSRect) {
        
        NSColor.black.setFill()
        self.bounds.fill()
        
        func clipRect(forNLevel nlevel: CGFloat, channel: Int) -> NSRect {
            let slices = (self.orientation == .vertical) ? self.bounds.sliceHorizontally(intoPieces: 2) : self.bounds.sliceVertically(intoPieces: 2)
            return slices[channel].scaled(x: self.orientation == .vertical ? 1.0 : nlevel, y: self.orientation == .vertical ? nlevel : 1.0)
        }
        
        guard
            let normalisedLevels = self._normalisedLevels,
            let ctx = NSGraphicsContext.current
        else { return }
        
        ctx.saveGraphicsState()

        (normalisedLevels.asArray().enumerated().map { clipRect(forNLevel: $0.element.0, channel: $0.offset) }).clip()

        gradient.draw(in: self.bounds, angle: (self.orientation == .vertical ? 90.0 : 0.0))

        ctx.restoreGraphicsState()
    }
    
}

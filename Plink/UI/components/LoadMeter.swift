//
//  LoadMeter.swift
//  Plink
//
//  Created by acb on 2019-07-20.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Foundation

class LoadMeterView: LinearMeterView {
    typealias Reading = Float
    @IBInspectable var backgroundColor: NSColor = NSColor.black
    
    var reading: Reading? {
        didSet {
            // TODO: partial invalidation/redrawing?
            self.needsDisplay = true
        }
    }
    
    let gradient = NSGradient(colors: [NSColor.green, NSColor.yellow, NSColor.red], atLocations: [0.0, 0.75, 1.0], colorSpace: NSColorSpace.deviceRGB)!

    override func draw(_ dirtyRect: NSRect) {
        
        self.backgroundColor.setFill()
        self.bounds.fill()
        
        let level = CGFloat(self.reading ?? 0.0)
        let rect = self.bounds.scaled(x: self.orientation == .vertical ? 1.0 : level, y: self.orientation == .vertical ? level : 1.0)

        guard
            let ctx = NSGraphicsContext.current
        else { return }

        ctx.saveGraphicsState()
        
        gradient.interpolatedColor(atLocation: level).setFill()
        rect.fill()

        ctx.restoreGraphicsState()

    }
}

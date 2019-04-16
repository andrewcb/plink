//
//  LevelSliderCell.swift
//  Plink
//
//  Created by acb on 16/04/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Cocoa

class LevelSliderCell: NSSliderCell {
    
    override func knobRect(flipped: Bool) -> NSRect {
        guard let size = self.controlView?.frame.size else { return .zero }
        let thickness: CGFloat = 7.0
        let extent = size.height - thickness
        let off = extent * (1.0 - CGFloat(self.doubleValue / self.maxValue))
        return NSRect(x: 0, y: off, width: size.width, height: thickness)
    }
    
    override func drawKnob(_ knobRect: NSRect) {
        NSImage(named: "levelslider")?.draw(in: knobRect)
    }
}

//
//  PanSliderCell.swift
//  Plink
//
//  Created by acb on 16/04/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Foundation

class PanSliderCell: NSSliderCell {
    override func drawKnob(_ knobRect: NSRect) {
        NSImage(named: "panslider")?.draw(in: knobRect)
    }
}

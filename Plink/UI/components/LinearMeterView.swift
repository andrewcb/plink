//
//  LinearMeterView.swift
//  Plink
//
//  Created by acb on 2019-07-20.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Cocoa

class LinearMeterView: NSView {
    enum Orientation {
        case vertical
        case horizontal
    }
    var orientation: Orientation = .vertical
    
    // logical coördinates, with respect to the current orientation
    var logicalLength: CGFloat { return self.orientation == .vertical ? self.bounds.height : self.bounds.width }
    var logicalBreadth: CGFloat { return self.orientation == .horizontal ? self.bounds.height : self.bounds.width }
}

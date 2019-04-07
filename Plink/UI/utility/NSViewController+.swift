//
//  NSViewController+.swift
//  Plink
//
//  Created by acb on 06/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

extension NSViewController {
    var world: World? {
        return self.view.window?.windowController?.document as? World
    }

}

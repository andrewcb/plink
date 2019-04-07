//
//  RenderProgressViewController.swift
//  Plink
//
//  Created by acb on 17/03/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Cocoa

class RenderProgressViewController: NSViewController {
    @IBOutlet var text: NSTextField!
    @IBOutlet var progress: NSProgressIndicator!
    
    func display(status: World.RenderStatus) {
        switch(status) {
            
        case .started:
            break
        case .progress(let v):
            DispatchQueue.main.async {
                self.progress.doubleValue = v
            }
        case .completed:
            break
        }
    }
}

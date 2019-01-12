//
//  WorkspaceViewController.swift
//  Plink
//
//  Created by acb on 06/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

/** The top-level workspace view controller, which acts mostly as a container for its component view controllers. */

class WorkspaceViewController: NSViewController {
    let coordinator = ModuleCoordinator()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.coordinator.stealingPolicy = .leaveBlank
        self.coordinator.specs = [
            ModuleCoordinator.Spec(name: "source", unique: true, shelveable: true, withStoryboardID: "Source"),
            ModuleCoordinator.Spec(name: "repl", unique: true, shelveable: true, withStoryboardID: "REPL"),
            ModuleCoordinator.Spec(name: "cueList", unique: true, shelveable: true, withStoryboardID: "CueList")
        ]
    }
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let site = segue.destinationController as? ModuleSiteViewController {
            switch(segue.identifier) {
            case "BL": site.currentModuleName = "source"
            case "BR": site.currentModuleName = "repl"
            default:
                print("Unknown module segue: \(segue.identifier)")
                break
            }
            site.coordinator = self.coordinator
            self.coordinator.register(site)
            site.menuPosition = .topTrailing
            site.menuOverlapsContainer = true
            site.textColor = NSColor(white: 0.0, alpha: 1.0)
            site.backgroundColor = NSColor(white: 1.0, alpha: 0.2)
        }
    }
    
    @IBAction func renderAudioSelected(_ sender: Any) {
        guard let window = self.view.window else { fatalError("No window?!")}
        let panel = NSSavePanel()
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser // TODO: remember the last render directory, either on a per-document basis or in global defaults
        let optsVC = self.storyboard!.instantiateController(withIdentifier: "RenderOptions") as! NSViewController
        let optsView = optsVC.view
        panel.accessoryView = optsView
        
        panel.beginSheetModal(for: window) { (response) in
            if response == NSApplication.ModalResponse.OK, let url = panel.url {
                print("Will render to \(url)")
            }
        }
    }
}

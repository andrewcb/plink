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
            ModuleCoordinator.Spec(name: "cueList", unique: true, shelveable: true, withStoryboardID: "CueList"),
            ModuleCoordinator.Spec(name: "cycleList", unique: true, shelveable: true, withStoryboardID: "CycleList")
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
        guard let window = self.view.window, let activeDocument = self.world else { fatalError("No window or activeDocument?!")}
        let panel = NSSavePanel()
        panel.prompt = "Render"
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = "output.aif"
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser // TODO: remember the last render directory, either on a per-document basis or in global defaults
        let optsVC = self.storyboard!.instantiateController(withIdentifier: "RenderOptions") as! RenderOptionsViewController
        let optsView = optsVC.view
        panel.accessoryView = optsView
        
        panel.beginSheetModal(for: window) { (response) in
            if response == NSApplication.ModalResponse.OK, let url = panel.url {
                let request = World.RenderRequest(subject: optsVC.requestSubject, destination: .file(url), options: optsVC.requestOptions)
//                print("RenderRequest: \(request)")
                
                let progressWC = self.storyboard!.instantiateController(withIdentifier: "RenderProgress") as! NSWindowController
                let progressVC = progressWC.contentViewController! as! RenderProgressViewController
                window.beginSheet(progressWC.window!, completionHandler: nil)
                DispatchQueue.global().async {
                    do {
                    try activeDocument.render(request, statusCallback: progressVC.display(status:))
                        DispatchQueue.main.async {
                            window.endSheet(progressWC.window!)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            window.endSheet(progressWC.window!)
                            let alert = NSAlert(error: error)
                            alert.messageText = "Rendering failed: \(error)"
                            alert.runModal()
                        }
                    }
                }
            }
        }
    }
}

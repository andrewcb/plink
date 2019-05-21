//
//  TriptychViewController.swift
//  Plink
//
//  Created by acb on 2019-05-21.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Foundation

/**
 A view controller with a central pane and collapsible left/right panes, managed by a NSSplitView.
 */

class TriptychViewController: NSViewController {
    class SplitFlagButton: NSTextField {
        enum ViewPosition {
            case left
            case right
        }
        
        enum State {
            case open
            case closed
        }
        
        private let labelText: [ViewPosition: [State:String]] = [
            .left: [ .open: "<", .closed: ">" ],
            .right: [ .open: ">", .closed: "<" ]
        ]
        
        private func updateLabel() {
            self.stringValue = labelText[self.position]![self.state]!
        }
        
        let position: ViewPosition
        var state: State {
            didSet { self.updateLabel() }
        }
        
        var onClick: (()->())?
        
        init(position: ViewPosition) {
            self.position = position
            self.state = .open
            super.init(frame: .zero)
            self.isEditable = false
            self.isBordered = false
            self.drawsBackground = true
            self.backgroundColor = NSColor(white: 1.0, alpha: 0.4)
            self.textColor = NSColor(white: 0.0, alpha: 1.0)
            self.translatesAutoresizingMaskIntoConstraints = false
            
            self.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(self.clicked)))
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        
        @objc func clicked(_ recognizer: NSClickGestureRecognizer) {
            self.onClick?()
        }
    }

    var splitView: NSSplitView!
    var leftButton: SplitFlagButton!
    var rightButton: SplitFlagButton!

    // The last user-set left/right widths
    var leftWidth: CGFloat?
    var rightWidth: CGFloat?
    
    var coordinator: ModuleCoordinator?
    
    override func loadView() {
        super.loadView()
        splitView = NSSplitView(frame: self.view.bounds)
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        self.view.addSubview(splitView)
        splitView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.splitView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.splitView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.splitView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        self.splitView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true

        self.splitView.addArrangedSubview(NSView())
        self.splitView.addArrangedSubview(NSView())
        self.splitView.addArrangedSubview(NSView())
        
        self.splitView.translatesAutoresizingMaskIntoConstraints = false
        let leftView = self.splitView.arrangedSubviews[0]
        leftView.translatesAutoresizingMaskIntoConstraints = false
        let rightView = self.splitView.arrangedSubviews[2]
        rightView.translatesAutoresizingMaskIntoConstraints = false
        
        func makeButton(position: SplitFlagButton.ViewPosition) -> SplitFlagButton {
            let btn = SplitFlagButton(position: position)
            self.view.addSubview(btn)
            btn.state = .open
            btn.widthAnchor.constraint(equalToConstant: 16).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 16).isActive = true
            btn.topAnchor.constraint(equalTo: self.splitView.topAnchor, constant: 2.0).isActive = true
            return btn
        }
        
        leftButton = makeButton(position: .left)
        leftButton.onClick = { [unowned self] () in
            if self.splitView.arrangedSubviews[0].frame.size.width < 1.0 {
                let centreWidth = self.splitView.arrangedSubviews[1].bounds.width
                let maxOpenWidth = min(centreWidth-10, (self.splitView.bounds.size.width*0.333).rounded(.down))
                let w =  self.leftWidth.flatMap { ($0 <  maxOpenWidth) ? $0 : nil } ?? (centreWidth * 0.333).rounded(.down)
                self.splitView.setPosition(w, ofDividerAt: 0)
                
            } else {
                self.leftWidth = self.splitView.arrangedSubviews[0].bounds.width
                self.splitView.setPosition(0, ofDividerAt: 0)
            }
        }
        
        rightButton = makeButton(position: .right)
        rightButton.onClick = { [unowned self] () in
            if self.splitView.isSubviewCollapsed(self.splitView.arrangedSubviews[2]) {
                let centreWidth = self.splitView.arrangedSubviews[1].bounds.width
                let maxOpenWidth = min(centreWidth-10, (self.splitView.bounds.size.width*0.333).rounded(.down))
                let w = self.rightWidth.flatMap { $0 < maxOpenWidth ? $0 : nil } ?? (centreWidth*0.333).rounded(.down)
                self.splitView.setPosition(self.splitView.bounds.width - w, ofDividerAt: 1)
            } else {
                self.rightWidth = self.splitView.arrangedSubviews[2].bounds.width
                self.splitView.setPosition(self.splitView.bounds.width, ofDividerAt: 1)
            }
        }

        self.loadEmbeddedViews()
    }
    
    override func viewWillAppear() {
        self.splitView.setPosition(0, ofDividerAt: 0)
        self.splitView.setPosition(self.splitView.frame.size.width, ofDividerAt: 1)
    }

    private func updateButtonPositions() {
        let leftView = self.splitView.arrangedSubviews[0]
        let rightView = self.splitView.arrangedSubviews[2]
        leftButton.frame.origin.x = max(0.0, leftView.frame.size.width - leftButton.frame.size.width)
        rightButton.frame.origin.x = min(self.splitView.frame.size.width, self.splitView.arrangedSubviews[0].frame.size.width + self.splitView.arrangedSubviews[1].frame.size.width + self.splitView.dividerThickness) - rightButton.frame.size.width
    }
    
    override func viewWillLayout() {
        super.viewWillLayout()
        self.updateButtonPositions()
    }
    
    fileprivate func updateButtons() {
        let leftOpen = self.splitView.arrangedSubviews[0].frame.size.width >= 1.0
        self.leftButton.state = leftOpen ? .open : .closed
        let rightOpen = !self.splitView.isSubviewCollapsed(self.splitView.arrangedSubviews[2])
        self.rightButton.state = rightOpen ? .open : .closed
        self.updateButtonPositions()
    }
    
    private func loadEmbeddedViews() {
        [nil, "mixer", nil].enumerated().forEach { (i, name) in
            let site = ModuleSiteViewController()
            site.currentModuleName = name.map { ModuleCoordinator.Spec.Name(rawValue: $0) }
            site.coordinator = self.coordinator
            self.coordinator?.register(site)
            site.menuPosition = .topTrailing
            site.menuOffset = CGSize(width: 18.0, height: 0.0)
            site.menuOverlapsContainer = true
            site.textColor = NSColor(white: 0.0, alpha: 1.0)
            site.backgroundColor = NSColor(white: 1.0, alpha: 0.4)
            let substrate = self.splitView.arrangedSubviews[i]
            self.addChild(site)
            substrate.addSubview(site.view)
            substrate.leftAnchor.constraint(equalTo: site.view.leftAnchor).isActive = true
            substrate.rightAnchor.constraint(equalTo: site.view.rightAnchor).isActive = true
            substrate.topAnchor.constraint(equalTo: site.view.topAnchor).isActive = true
            substrate.bottomAnchor.constraint(equalTo: site.view.bottomAnchor).isActive = true

        }
    }
}

extension TriptychViewController: NSSplitViewDelegate {
    func splitViewDidResizeSubviews(_ notification: Notification) {
        self.updateButtons()
    }
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return true
    }
}

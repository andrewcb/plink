//
//  ModuleSiteViewController.swift
//  Plink
//
//  Created by acb on 28/12/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

class ModuleSiteViewController: NSViewController {
    enum MenuPosition: Int {
        case topLeading = 0x00
        case topTrailing = 0x02
        case bottomLeading = 0x08
        case bottomTrailing = 0x0a
        
        var isLeading: Bool { return self.rawValue & 0x03 == 0x00 }
        var isTrailing: Bool { return self.rawValue & 0x03 == 0x02 }
        var isTop: Bool { return self.rawValue & 0x0c == 0x00 }
        var isBottom: Bool { return self.rawValue & 0x0c == 0x08 }
    }
    /// The position of the menu relative to the container
    var menuPosition: MenuPosition = .topTrailing {
        didSet { self.adjustConstraints() }
    }
    
    /// The offset of the menu from the corner of the container
    var menuOffset: CGSize = .zero {
        didSet {
            self.adjustConstraints()
        }
    }
    
    /// If true, the container fills the entire space, with the menu button overlapping it
    var menuOverlapsContainer: Bool = false {
        didSet { self.adjustConstraints() }
    }
    
    /** The colour of the label text on the menu button */
    var textColor: NSColor?
    /** The colour of the background of the button */
    var backgroundColor: NSColor?
    /** The text displayed in the menu button if the site is empty */
    var emptyText: String = "━━"
    
    private let selectionMenu = NSPopUpButton(frame: .zero, pullsDown: false)
    private let containerView = NSView(frame: .zero)
    
    var coordinator: ModuleCoordinator?
    
    private var availableModules: [ModuleCoordinator.Spec.Name] = []
    
    var currentModuleName: ModuleCoordinator.Spec.Name? {
        didSet {
            // The menu here is like Schrödinger's Cat: it does not exist until the instant before it is opened. Which means that when we set the name, it has one item, which is the name.
            
            self.selectionMenu.removeAllItems()
            self.selectionMenu.addItem(withTitle: self.currentModuleName?.rawValue ?? self.emptyText)
            self.selectionMenu.selectItem(at: 0)
            self.colourItems()
        }
    }
    var currentViewController: NSViewController? {
        didSet(old) {
            if let old = old {
                old.removeFromParent()
                old.view.removeFromSuperview()
            }
            if let vc = self.currentViewController {
                let view = vc.view
                self.addChild(vc)
                view.frame = self.containerView.bounds
                self.containerView.addSubview(view)
                view.translatesAutoresizingMaskIntoConstraints = true
                view.autoresizingMask = [ .height, .width ]
            }
        }
    }
    
    private func colourItems() {
        guard let textColor = self.textColor else { return }
        for item in self.selectionMenu.itemArray {
            item.attributedTitle = NSAttributedString(
                string: item.title, attributes: [
                    .foregroundColor: textColor,
                    ])
        }
    }
    
    override func loadView() {
        self.view = NSView(frame: .zero)
        self.selectionMenu.wantsLayer =  true
        self.selectionMenu.layer?.backgroundColor = self.backgroundColor?.cgColor
    }
    
    // Layout constraints
    private var ctrTConstraint: NSLayoutConstraint?
    private var ctrBConstraint: NSLayoutConstraint?
    private var menuCtrVConstraint: NSLayoutConstraint? // menu.bottom = ctr.top
    private var ctrMenuVConstraint: NSLayoutConstraint? // menu.top = ctr.bottom
    private var menuTConstraint: NSLayoutConstraint?
    private var menuBConstraint: NSLayoutConstraint?
    private var menuLConstraint: NSLayoutConstraint?  // here, 'L' stands for 'Leading'
    private var menuRConstraint: NSLayoutConstraint?  // here, 'R' stands for 'tRailing'
    
    private func adjustConstraints() {
        self.ctrTConstraint?.isActive = self.menuPosition.isBottom || self.menuOverlapsContainer
        self.ctrBConstraint?.isActive = self.menuPosition.isTop || self.menuOverlapsContainer
        self.menuCtrVConstraint?.isActive = self.menuPosition.isTop && !self.menuOverlapsContainer
        self.ctrMenuVConstraint?.isActive = self.menuPosition.isBottom  && !self.menuOverlapsContainer
        self.menuTConstraint?.isActive = self.menuPosition.isTop
        self.menuBConstraint?.isActive = self.menuPosition.isBottom
        self.menuLConstraint?.isActive = self.menuPosition.isLeading
        self.menuRConstraint?.isActive = self.menuPosition.isTrailing
        self.menuTConstraint?.constant = -self.menuOffset.height
        self.menuBConstraint?.constant = self.menuOffset.height
        self.menuLConstraint?.constant = -self.menuOffset.width
        self.menuRConstraint?.constant = self.menuOffset.width
    }
    
    override func viewDidLoad() {
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(containerView)
        self.view.addSubview(selectionMenu)
        self.containerView.translatesAutoresizingMaskIntoConstraints = false
        
        self.ctrBConstraint = self.containerView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0)
        self.menuCtrVConstraint = self.containerView.topAnchor.constraint(equalTo: self.selectionMenu.bottomAnchor, constant: 0)
        self.ctrTConstraint = self.containerView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0)
        self.ctrMenuVConstraint = self.containerView.bottomAnchor.constraint(equalTo: self.selectionMenu.topAnchor, constant: 0)
        
        self.containerView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0).isActive = true
        self.containerView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0).isActive = true
        self.selectionMenu.heightAnchor.constraint(greaterThanOrEqualToConstant: 16.0).isActive = true
        
        self.menuLConstraint = self.view.leadingAnchor.constraint(equalTo: selectionMenu.leadingAnchor, constant: 0)
        self.menuRConstraint = self.view.trailingAnchor.constraint(equalTo: selectionMenu.trailingAnchor, constant: 0)
        self.menuTConstraint = self.view.topAnchor.constraint(equalTo: selectionMenu.topAnchor, constant: 0)
        self.menuBConstraint = self.view.bottomAnchor.constraint(equalTo: selectionMenu.bottomAnchor, constant: 0)
        
        self.adjustConstraints()
        
        self.selectionMenu.target = self
        self.selectionMenu.action = #selector(self.menuAction)
        NotificationCenter.default.addObserver(forName: NSPopUpButton.willPopUpNotification, object: self.selectionMenu, queue: nil) { [weak self] (notification) in
            guard
                let self = self,
                let coord = self.coordinator
                else { return }
            self.availableModules = coord.availableModules(forSite: self)
            self.selectionMenu.removeAllItems()
            self.selectionMenu.addItems(withTitles: self.availableModules.map { $0.rawValue })
            let currentlySelected = self.availableModules.enumerated().first(where: { $0.element == self.currentModuleName})?.offset ?? -1
            self.selectionMenu.selectItem(at: currentlySelected)
        }
        
        self.selectionMenu.isBordered = false
        self.selectionMenu.addItem(withTitle: self.emptyText)
        self.selectionMenu.translatesAutoresizingMaskIntoConstraints = false
        self.colourItems()
        
        self.view.needsLayout =  true
    }
    
    override func viewWillAppear() {
        if let name = self.currentModuleName {
            self.coordinator?.requestLoad(ofModule: name, forSite: self)
        }
    }
    
    @objc func menuAction() {
        guard self.availableModules.count > self.selectionMenu.indexOfSelectedItem else { return }
        let name = self.availableModules[self.selectionMenu.indexOfSelectedItem]
        self.coordinator?.requestLoad(ofModule: name, forSite: self)
        
    }
}

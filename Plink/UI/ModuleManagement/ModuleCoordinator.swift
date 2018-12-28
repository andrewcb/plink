//
//  ModuleCoordinator.swift
//  Plink
//
//  Created by acb on 28/12/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Cocoa

/** The object coordinating the opening of modules across a user interface; this handles uniqueness rules, stealing, and the shelving of live view controllers (where enabled) */
class ModuleCoordinator {
    
    enum StealingPolicy {
        case deny // displayed unique modules may not be stolen to new sites
        case swap // on stealing, the old site gets the new site's previous contents
        case leaveBlank // on stealing, leave the old site empty, and shelve/destroy the new site's previous contents
    }
    
    /// Can a slot steal a unique module that is already in another slot, and if so, how is this handled?
    var stealingPolicy: StealingPolicy = .swap
    
    struct Spec {
        
        public struct Name : Hashable, Equatable, RawRepresentable {
            public var rawValue: String
        }
        
        enum Provenance {
            case constructor(()->NSViewController?)
            case fromStoryboard(NSStoryboard, NSStoryboard.SceneIdentifier)
        }
        
        /// The module's name, which serves as a unique identifier and menu text
        let name: Spec.Name
        /// If true, only one instance of this module may exist at once
        let unique: Bool
        /// If true, this module's ViewController will be shelved on eviction and reused when next selected, rather than destroyed and recreated. Note: this does not persist view controllers beyond the lifecycle of the containing ModuleCoordinator.
        let shelveable: Bool
        /// How the view controller is to be constructed
        let provenance: Provenance
        
        func construct() -> NSViewController? {
            switch(self.provenance) {
            case .constructor(let c): return c()
            case .fromStoryboard(let storyboard, let id):
                return storyboard.instantiateController(withIdentifier: id) as? NSViewController
            }
        }
    }
    
    /// The specifications of available modules and how to construct them
    var specs: [Spec] = [] {
        didSet {
            self.specsByName = [Spec.Name:Spec](self.specs.map { ($0.name, $0)}, uniquingKeysWith: { $1 })
            self.shelvedViewControllers = [:]
        }
    }
    private var specsByName: [Spec.Name:Spec] = [:]
    
    private var sites: [ModuleSiteViewController] = []
    
    private var currentModule: [ModuleSiteViewController:Spec.Name] = [:]
    // The most recent site to load the module; if this module is unique, it will be the one which currently has it. If it's not unique, this value is not  used.
    private var currentSite: [Spec.Name:ModuleSiteViewController] = [:]
    
    private var shelvedViewControllers: [Spec.Name:NSViewController] = [:]
    
    func register(_ site: ModuleSiteViewController) {
        self.sites.append(site)
        self.currentModule[site] = nil
    }
    
    func availableModules(forSite site: ModuleSiteViewController) -> [Spec.Name] {
        
        let filterPredicate = self.stealingPolicy == .deny ? { (spec: Spec) in !spec.unique || self.currentSite[spec.name] == nil } : { _ in true }
        return ([ self.currentModule[site] ]).compactMap { $0 } + self.specs
            .filter { (spec) in filterPredicate(spec) && (self.currentModule[site].map { m in m != spec.name } ?? true)  }
            .map { $0.name }
    }
    
    private func procureViewController(forModule moduleName: Spec.Name) -> NSViewController? {
        if let unshelved = self.shelvedViewControllers[moduleName] {
            self.shelvedViewControllers[moduleName] = nil
            return unshelved
        }
        return self.specsByName[moduleName]?.construct()
    }
    
    private func shelveOrDestroyCurrentContents(ofSite site: ModuleSiteViewController) {
        defer { site.currentViewController = nil }
        guard
            let vc = site.currentViewController,
            let module = self.currentModule[site],
            let specs = self.specsByName[module]
            else { return }
        if specs.shelveable {
            self.shelvedViewControllers[module] = vc
        }
        self.currentSite[module] = nil
    }
    
    private func dumpState() {
        let pseudonyms = [ModuleSiteViewController:Int](uniqueKeysWithValues: self.sites.enumerated().map { ($0.element, $0.offset)})
        print("Site -> Module:")
        for (site, module) in self.currentModule {
            print("\(pseudonyms[site]!) -> \(module)")
        }
        
        print("Module -> Site")
        for (module, site) in self.currentSite {
            print("\(module) -> \(pseudonyms[site]!)")
        }
    }
    
    private func setModule(_ module: Spec.Name, withViewController vc: NSViewController, forSite site: ModuleSiteViewController) {
        site.currentViewController = vc
        site.currentModuleName = module
        self.currentModule[site] = module
        self.currentSite[module] = site
    }
    // called by a site to request a module change for it (and any knock-on effects that happen elsewhere, i.e., module stealing/swapping)
    func requestLoad(ofModule moduleName: Spec.Name, forSite site: ModuleSiteViewController) {
        
        if self.specsByName[moduleName]?.unique ?? false, let donorSite = self.currentSite[moduleName] {
            if self.stealingPolicy == .deny  { return }
            guard let stolen = donorSite.currentViewController else { return }
            if self.stealingPolicy == .swap,
                let exchangedVC = site.currentViewController,
                let exchangedModule = self.currentModule[site]
            {
                site.currentViewController = nil
                self.setModule(exchangedModule, withViewController: exchangedVC, forSite: donorSite)
                
            } else {
                donorSite.currentViewController = nil
                donorSite.currentModuleName = nil
                self.currentModule[donorSite] = nil
            }
            self.shelveOrDestroyCurrentContents(ofSite: site)
            self.setModule(moduleName, withViewController: stolen, forSite: site)
            
            self.dumpState()
            return
        }
        
        self.shelveOrDestroyCurrentContents(ofSite: site)
        
        guard let vc = self.procureViewController(forModule: moduleName) else { return }
        self.setModule(moduleName, withViewController: vc, forSite: site)
        self.dumpState()
    }
}

/// Convenience constructors for specs, making the DSL terser and more elegant
extension ModuleCoordinator.Spec {
    init(name: ModuleCoordinator.Spec.Name, unique: Bool = false, shelveable: Bool = false, constructor: @escaping (()->NSViewController?)) {
        self.init(name: name, unique: unique, shelveable: shelveable, provenance: .constructor(constructor))
    }
    
    init(name: ModuleCoordinator.Spec.Name, unique: Bool = false, shelveable: Bool = false, withStoryboardID id: NSStoryboard.SceneIdentifier, fromStoryboard storyboard: NSStoryboard? = nil) {
        // the NSStoryboard.main! is ugly, but that's the only way of having this be callable inline without hedging; yes, it will die horribly if there's no main storyboard, but (a) that happens early, and (b) the programmer using this can take responsibility for having a main storyboard
        self.init(name: name, unique: unique, shelveable: shelveable, provenance: .fromStoryboard(storyboard ?? NSStoryboard.main!, id))
    }
}

extension ModuleCoordinator.Spec.Name: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
}

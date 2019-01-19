//
//  NSDraggingInfo+modernisation.swift
//  Plink
//
//  Created by acb on 19/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Cocoa

extension NSDraggingInfo {
    /** Return data in pasteboard item data strings that is successfully parsed by a function */
    func enumeratedPasteboardItemData<A>(options enumOpts: NSDraggingItemEnumerationOptions = [], for view: NSView, searchOptions: [NSPasteboard.ReadingOptionKey: Any] = [:], forType pbType: NSPasteboard.PasteboardType, function: @escaping (String)->A?) -> [A] {
        var result = [A]()
        
        self.enumerateDraggingItems(options: enumOpts, for: view, classes: [NSPasteboardItem.self], searchOptions: searchOptions) { (item, _, stopPtr) in
            if let v = ((item.item as? NSPasteboardItem)?.string(forType: pbType)).flatMap({ function($0) }) {
                result.append(v)
            }
        }
        
        return result
    }
}

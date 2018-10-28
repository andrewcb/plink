//
//  NSRect+composable.swift
//  Plink
//
//  Created by acb on 27/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//
//  Composable extensions for NSRect

import Cocoa

/*
 rect.sliceHorizontally(pieces:8)[1] -> NSRect
 */


extension NSRect {
    /// A subscriptable sequence returning a succession of NSRects offset by an integral multiple of a size
    struct RectSeries {
        let itemSize: CGSize
        let increment: CGSize
        let offset: CGPoint
        let count: Int? // for iteration
        
        subscript(index: Int) -> NSRect {
            return NSRect(origin: CGPoint(
                x: offset.x+increment.width*CGFloat(index),
                y: offset.y+increment.height*CGFloat(index)
            ), size: self.itemSize)
        }
    }
    
    /** Return a subscriptable series of equal horizontal slices */
    func sliceHorizontally(intoPieces pieces: Int) -> RectSeries {
        let w = self.width / CGFloat(pieces)
        return RectSeries(itemSize: CGSize(width: w, height: self.height), increment: CGSize(width: w, height:0), offset: self.origin, count: pieces)
    }
    /** Return a subscriptable series of equal vertical slices */
    func sliceVertically(intoPieces pieces: Int) -> RectSeries {
        let h = self.height / CGFloat(pieces)
        return RectSeries(itemSize: CGSize(width: self.width, height: h), increment: CGSize(width: 0, height:h), offset: self.origin, count: pieces)
    }
    
    /** Multiply the size by X and or Y scaling factors */
    func scaled(x: CGFloat = 1.0, y: CGFloat = 1.0) -> NSRect {
        return NSRect(origin: self.origin, size: CGSize(width: self.width*x, height: self.height*y))
    }
    
}

//
//  StereoPair.swift
//  Plink
//
//  Created by acb on 19/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Foundation

/// A container type for a stereo pair of any given type.

struct StereoPair<T> {
    /// the left channel
    let left: T
    /// the right channel
    let right: T
    
    // functor instance
    func map<U>(_ f: ((T) throws -> (U))) rethrows -> StereoPair<U> {
        return StereoPair<U>(left: try f(self.left), right: try f(self.right))
    }
    
    /// Convert to an array for things that need one
    func asArray() -> [T] { return [self.left, self.right] }
}

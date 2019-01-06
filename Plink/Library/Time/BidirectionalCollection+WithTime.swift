//
//  BidirectionalCollection+WithTime.swift
//  Plink
//
//  Created by acb on 05/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Foundation

extension BidirectionalCollection where Element: WithTime {
    /// Given an index of a collection ordered by ascending time, return the index of the first element in the collection at or after the given time; this may be EndIndex if there are no matching elements.
    func index(bySeekingFrom srcIndex: Self.Index, toStartOfElementsNotBefore time: TickTime) -> Self.Index {
        if srcIndex >= self.endIndex || self[srcIndex].time >= time {
            var i = Swift.min(srcIndex, self.endIndex)
            while i != self.startIndex, self[self.index(before: i)].time >= time {
                i = self.index(before: i)
            }
            return i
        } else {
            var i = srcIndex
            while self.index(after: i) != self.endIndex, self[self.index(after:i)].time < time {
                i = self.index(after: i)
            }
            return self.index(after: i)
        }
    }
}

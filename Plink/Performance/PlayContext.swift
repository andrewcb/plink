//
//  PlayContext.swift
//  Plink
//
//  Created by acb on 05/01/2019.
//  Copyright © 2019 Kineticfactory. All rights reserved.
//

import Foundation

/**
 A PlayContext is the state used during a period of continuous playback of a Score. Its lifecycle is confined to the period of playback, and it stores continuous state for that period (such as iterators/cursors to upcoming program items, eliminating linear seeks in most cases). For the sake of recoverability, the PlayContext can check and adjust its state accordingly in the case of an event requiring it to do so (i.e., the Score being amended) happening.
 */
class PlayContext {
    let score: ScoreModel
    var currentTime: TickTime
    
    init(score: ScoreModel, time: TickTime) {
        self.score = score
        self.currentTime = time
        self.cueListCursor = score.cueList.index(bySeekingFrom: score.cueList.startIndex, toStartOfElementsNotBefore: time)
    }
    
    func advance(to time: TickTime) {
        self.currentTime = time
        while self.cueListCursor < score.cueList.endIndex && score.cueList[self.cueListCursor].time < time { self.cueListCursor = self.cueListCursor.advanced(by: 1)}
    }
    
    // MARK: the cue list
    
    private var cueListCursor: ScoreModel.CueList.Index
    
    func nextCue(forTime time: TickTime) -> ScoreModel.Cue? {
        guard self.cueListCursor < score.cueList.endIndex && score.cueList[self.cueListCursor].time <= time else { return nil }
        defer { self.cueListCursor = score.cueList.index(after: self.cueListCursor) }
        return score.cueList[self.cueListCursor]
    }
    
    /// Called when the cue list has changed, to adjust the cue list cursor
    func adjustForCueListChange() {
        self.cueListCursor = score.cueList.index(bySeekingFrom: self.cueListCursor, toStartOfElementsNotBefore: self.currentTime)
    }
}

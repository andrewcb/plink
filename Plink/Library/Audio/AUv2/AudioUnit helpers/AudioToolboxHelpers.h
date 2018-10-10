//
//  AudioToolboxHelpers.h
//  AUInstHostTest
//
//  Created by acb on 05/12/2017.
//  Copyright © 2017 acb. All rights reserved.
//

#ifndef AudioToolboxHelpers_h
#define AudioToolboxHelpers_h

#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <CoreAudio/CoreAudio.h>
#import <Cocoa/Cocoa.h>

NSView * __nullable loadInterfaceViewForAudioUnit(AudioUnit au, struct CGSize size);

#endif /* AudioToolboxHelpers_h */

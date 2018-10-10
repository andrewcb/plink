//
//  AudioToolboxHelpers.m
//  AUInstHostTest
//
//  Created by acb on 05/12/2017.
//  Copyright © 2017 acb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <CoreAudio/CoreAudio.h>
#import <Cocoa/Cocoa.h>

// for some reason, Apple don't seem to put this in their headers
@protocol AUCocoaUIBaseProtocol
- (NSView*)uiViewForAudioUnit:(AudioUnit)au withSize: (struct CGSize)size;
@end

NSView * __nullable loadInterfaceViewForAudioUnit(AudioUnit au, struct CGSize size) {
    AudioUnitCocoaViewInfo cocoaViewInfo;
    UInt32 viewInfoSize = sizeof(cocoaViewInfo);
    
    if (AudioUnitGetProperty(au, kAudioUnitProperty_CocoaUI, kAudioUnitScope_Global, 0, &cocoaViewInfo, &viewInfoSize) == noErr) {
        NSURL *bundleURL = (__bridge NSURL *)(cocoaViewInfo.mCocoaAUViewBundleLocation);
        NSString *className = (__bridge NSString *)(cocoaViewInfo.mCocoaAUViewClass[0]);
        NSBundle *bundle = [NSBundle bundleWithURL:bundleURL];
        Class cl = [bundle classNamed:className];
        id<AUCocoaUIBaseProtocol> __autoreleasing inst = [[cl alloc] init];
        return [inst uiViewForAudioUnit:au withSize:size];
    }
    return nil;
}

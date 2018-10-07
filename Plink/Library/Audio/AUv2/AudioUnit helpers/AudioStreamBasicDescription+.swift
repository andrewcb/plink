import Foundation
import CoreAudio

public extension AudioStreamBasicDescription {
    public var isFloat: Bool { return (self.mFormatFlags & kAudioFormatFlagIsFloat) != 0 }
    public var isSignedInteger: Bool { return (self.mFormatFlags & kAudioFormatFlagIsSignedInteger) != 0 }
    public var isNonInterleaved: Bool { return (self.mFormatFlags & kAudioFormatFlagIsNonInterleaved) != 0 }
}

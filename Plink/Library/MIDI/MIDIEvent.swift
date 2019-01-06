import Foundation

// A low-level MIDI Event type; this is just the 3 bytes sent to the device, wrapped in some useful methods

public struct MIDIEvent {
    var value: UInt32
    
    public init(statusByte: UInt8, data1: UInt8, data2: UInt8) {
        self.value = UInt32(statusByte) | UInt32(data1)<<8 | UInt32(data2)<<16
    }
    
    public var statusByte: UInt8 { return UInt8(self.value & 0xff) }
    public var data1: UInt8 { return UInt8((self.value >> 8) & 0xff) }
    public var data2: UInt8 { return UInt8((self.value >> 16) & 0xff) }
}

public typealias MIDIEventWithTime = TimedBox<MIDIEvent>

extension MIDIEvent: CustomStringConvertible {
    public var description: String {
        
        func format(note: UInt8) -> String {
            let sc = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
            return "\(sc[Int(note%12)])\(note/12)"
        }
        
        switch(self.statusByte >> 4) {
        case 8: return "OFF.\(String(format: "%01x", self.statusByte&0x0f)) \(format(note:self.data1)) \(self.data2)"
        case 9: return "ON.\(String(format: "%01x", self.statusByte&0x0f)) \(format(note:self.data1)) \(self.data2)"
        default: return String(format:"%02x %02x %02x", self.statusByte, self.data1, self.data2)
        }
    }
}

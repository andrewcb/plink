import Foundation

// A higher-level MIDI Note type, with duration; this decomposes into MIDIEvents
public struct MIDINote {
    public let note: UInt8
    public let channel: UInt8
    public let velocity: UInt8
    public let duration: TickDuration
    
    public init(note: UInt8, channel: UInt8, velocity: UInt8, duration: TickDuration) {
        self.note = note
        self.channel = channel
        self.velocity = velocity
        self.duration = duration
    }
}
public typealias MIDINoteWithTime = ItemWithTime<MIDINote>

extension MIDINote: CustomStringConvertible {
    public var description: String {
        func format(note: UInt8) -> String {
            let sc = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
            return "\(sc[Int(note%12)])\(note/12)"
        }
        
        return "\(String(format:"%01x", self.channel)) \(format(note: self.note)) \(self.velocity), \(self.duration)"

    }
}

extension WithTime where Value == MIDINote {
    public var noteOnEvent: ItemWithTime<MIDIEvent> {
        return ItemWithTime(time: self.time, value: MIDIEvent(statusByte: 0x90 | (self.value.channel & 0x0f), data1: self.value.note & 0x7f, data2: self.value.velocity & 0x7f))
    }

    public var noteOffEvent: ItemWithTime<MIDIEvent> {
        return ItemWithTime(time: self.time+self.value.duration, value: MIDIEvent(statusByte: 0x80 | (self.value.channel & 0x0f), data1: self.value.note & 0x7f, data2: self.value.velocity & 0x7f))
    }

}


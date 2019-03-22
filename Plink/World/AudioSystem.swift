//
//  AudioSystem.swift
//  Plink
//
//  Created by acb on 07/10/2018.
//  Copyright © 2018 Kineticfactory. All rights reserved.
//

import Foundation
import AudioToolbox

class AudioSystem {
    public enum OutputMode: CaseIterable {
        /// Play the output to the hardware output in real time
        case play
        /// Render the output offline, for the benefit of anything recording the buffers
        case offlineRender
    }
    
    /// The current output mode
    var outputMode: OutputMode = .play {
        didSet(prev) {
            guard self.outputMode != prev else { return }
            // TODO: rewire the graph here
            
            self.outNode = nil // remove the old output node
            let outputDescriptionForMode: [OutputMode: AudioComponentDescription] = [
                .play: .defaultOutput,
                .offlineRender: .genericOutput
            ]
            self.outNode = try! self.graph.addNode(withDescription: outputDescriptionForMode[self.outputMode]!)
        }
    }

    let graph: AudioUnitGraph<ManagedAudioUnitInstance>
    let mixerNode: AudioUnitGraph<ManagedAudioUnitInstance>.Node
    var outNode: AudioUnitGraph<ManagedAudioUnitInstance>.Node? {
        willSet(v) {
            if v == nil && self.outNode != nil {
                try! self.mixerNode.disconnectOutput()
                try! self.outNode!.removeFromGraph()
            }
        }
        didSet(prev) {
            if let outNode = self.outNode {
                try! self.mixerNode.connect(to: outNode)
                try! self.setUpAudioRenderCallback()
            }
        }
    }
    
    // TODO: what is the provenance of this?
    let numSamplesPerBuffer: UInt32 = 512
    // TODO someday: make this configurable
    let sampleRate = 44100
    var bufferDuration: Float64 { return Float64(numSamplesPerBuffer)/Float64(sampleRate) }
    
    struct ChannelLevelReading {
        let average: AudioUnitParameterValue
        let peak: AudioUnitParameterValue
    }

    typealias StereoLevelReading = StereoPair<ChannelLevelReading>
    
    // Add the render notify function here

    private func setUpAudioRenderCallback() throws {
        guard let outinst = try self.outNode?.getInstance() else {
            return
        }

        let audioRenderCallback: AURenderCallback = { (inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumFrames, ioData) -> OSStatus in
            
            let instance = unsafeBitCast(inRefCon, to: AudioSystem.self)
            
            let actionFlags = ioActionFlags.pointee
            if actionFlags.contains(.unitRenderAction_PreRender) {
                // instance.preRender(inTimeStamp.pointee.mSampleTime)
                // NOTE: the timestamp is reset every time the graph is stopped/started
                instance.onPreRender?(Int(inNumFrames), instance.sampleRate)
            }
            if ioActionFlags.pointee.contains(.unitRenderAction_PostRender) && instance.outputMode == OutputMode.offlineRender {
                //                print("post-render; buffers = \(ioData), tap = \(instance.postRenderTap)")
            }
            if ioActionFlags.pointee.contains(.unitRenderAction_PostRender),
                let buffers = ioData,
                let tap = instance.postRenderTap
            {
                //                print("- calling post-render tap")
                tap(buffers, inNumFrames)
            }
            
            return noErr
        }
        
        AudioUnitAddRenderNotify(outinst.auRef, audioRenderCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))

    }
    
    private func getMeterLevel(forScope scope: AudioUnitScope, element: AudioUnitElement) -> StereoLevelReading? {
        guard
            let audioUnit = mixerNode._audioUnit
        else { return nil }
        do {
            let lavg = try audioUnit.getParameterValue(kMultiChannelMixerParam_PostAveragePower, scope: scope, element: element)
            let lpeak = try audioUnit.getParameterValue(kMultiChannelMixerParam_PostPeakHoldLevel, scope: scope, element: element)
            let ravg = try audioUnit.getParameterValue(kMultiChannelMixerParam_PostAveragePower+1, scope: scope, element: element)
            let rpeak = try audioUnit.getParameterValue(kMultiChannelMixerParam_PostPeakHoldLevel+1, scope: scope, element: element)
            return StereoLevelReading(left: ChannelLevelReading(average: lavg, peak: lpeak), right: ChannelLevelReading(average: ravg, peak: rpeak))

        } catch {
            print("getMeterLevel: error \(error)")
            return nil
        }
    }
    public var masterLevel: StereoLevelReading? {
        return self.getMeterLevel(forScope: kAudioUnitScope_Output, element: 0)
    }
    public func level(forChannel channel: Int) -> StereoLevelReading? {
        return self.getMeterLevel(forScope: kAudioUnitScope_Input, element: AudioUnitElement(channel))
    }
    
    /// A Channel, currently consisting of an instrument and some inserts
    class Channel {
        var name: String {
            didSet {
                self.audioSystem?.channelsChanged()
            }
        }
        var audioSystem: AudioSystem? = nil
        var index: Int = -1
        var instrument: AudioUnitGraph<ManagedAudioUnitInstance>.Node? = nil {
            didSet(prev) {
                guard prev != self.instrument else { return }
                do {
                    try self.audioSystem?.stopGraph()
                    try prev?.disconnectAll()
                    try prev?.removeFromGraph()
                    if let firstInsert = inserts.first {
                        try self.instrument?.connect(to: firstInsert)
                    }
                    self._headNode = self.findHeadNode()
                    try self.audioSystem?.startGraph()
                } catch {
                    fatalError("failed to disconnect/connect nodes: \(error)")
                }
            }
        }
        var _inserts: [AudioUnitGraph<ManagedAudioUnitInstance>.Node] = []
        var inserts: [AudioUnitGraph<ManagedAudioUnitInstance>.Node] {
            return self._inserts
        }
        // methods for adding inserts
        func add(insert: AudioUnitGraph<ManagedAudioUnitInstance>.Node) throws {
            let lastHead = self.headNode
            self._inserts.append(insert)
            try self.audioSystem?.stopGraph()
            try lastHead?.disconnectOutput()
            try lastHead?.connect(to: insert)
            self._headNode = self.findHeadNode()
            try self.audioSystem?.startGraph()
            
        }
        
        /// The node that's at the end of the chain
        var _headNode: AudioUnitGraph<ManagedAudioUnitInstance>.Node? {
            didSet(prev) {
                self.onHeadNodeChanged?(self, prev)
                print("head node changed:")
                audioSystem!.graph.dump()
            }
        }
        var headNode: AudioUnitGraph<ManagedAudioUnitInstance>.Node? {
            return self._headNode
        }
        private func findHeadNode() -> AudioUnitGraph<ManagedAudioUnitInstance>.Node? {
            return self.inserts.last ?? self.instrument
        }
        
        // notification method; called with the Channel and
        var onHeadNodeChanged: ((Channel,AudioUnitGraph<ManagedAudioUnitInstance>.Node?)->())? = nil
        
        init(name: String, instrument: AudioUnitGraph<ManagedAudioUnitInstance>.Node? = nil, inserts: [AudioUnitGraph<ManagedAudioUnitInstance>.Node] = []) {
            self.name = name
            self.instrument = instrument
            self._inserts = inserts
            self._headNode = self.findHeadNode()
        }
        
        init(graph: AudioUnitGraph<ManagedAudioUnitInstance>, snapshot: AudioSystemModel.ChannelModel) throws {
            self.name = snapshot.name
            self.instrument = try snapshot.instrument.map {
                try AudioUnitGraph.Node(graph: graph, presetData: $0)
            }
            self._inserts = try snapshot.inserts.map {
                try AudioUnitGraph.Node(graph: graph, presetData: $0)
            }
            self._headNode = self.findHeadNode()
            
            self.gain = snapshot.gain
            self.pan = snapshot.pan
        }
        
        func loadInstrument(fromDescription description: AudioComponentDescription) throws {
            self.instrument = try self.audioSystem?.graph.addNode(withDescription: description)
            //            print("Instrument loaded")
            audioSystem!.graph.dump()
        }
        
        func addInsert(fromDescription description: AudioComponentDescription) throws {
            try self.audioSystem?.stopGraph()
            
            guard let insert = try self.audioSystem?.graph.addNode(withDescription: description) else { return }
            try self.add(insert: insert)
            //            print("Insert loaded")
            //            audioSystem!.graph.dump()
            try self.audioSystem?.startGraph()
            
        }
        
        var gain: AudioUnitParameterValue {
            get { return self.audioSystem.flatMap { try? $0.getGain(forChannelIndex: self.index) } ?? Float32.nan }
            set(v) { try? self.audioSystem?.setGain(forChannelIndex: self.index, to: v) }
        }
        var pan: AudioUnitParameterValue {
            get { return self.audioSystem.flatMap { try? $0.getPan(forChannelIndex: self.index) }.map { ($0*2.0)-1.0 } ?? Float32.nan }
            set(v) { try? self.audioSystem?.setPan(forChannelIndex: self.index, to: (v+1.0)*0.5) }
        }

        func snapshot() throws -> AudioSystemModel.ChannelModel {
            let instPresetData = try self.instrument?.getPresetData()
            return AudioSystemModel.ChannelModel(name: self.name, gain: self.gain, pan: self.pan, instrument: instPresetData, inserts: try self.inserts.map { try $0.getPresetData() })
        }
    }
    
    var channels: [Channel] = []
    
    /// posted when the script text changes or the script is eval'd
    static let channelsChangedNotification = Notification.Name("AudioSystem.ChannelsChanged")

    
    private func channelsChanged() {
        NotificationCenter.default.post(name: AudioSystem.channelsChangedNotification, object: nil)
    }
    
    /// The callback, called from the pre-render method, to advance the time by a number of frames and cause any pending actions from the currently playing sequence and/or immediate queue to be executed, with effect on the audio system
    /// arguments: number of frames, number of frames per second (sample rate)
    typealias PreRenderCallback = ((Int, Int)->())
    var onPreRender: PreRenderCallback?
    
    /// If present, this function is called with the freshly rendered buffers immediately after rendering.
    public var postRenderTap: ((UnsafeMutablePointer<AudioBufferList>, UInt32) -> ())? = nil
    
    /// called when the audio processing graph is stopped; used to cancel any pending operations, &c.
    var onAudioInterruption: (()->())?
    
    
    fileprivate func startGraph() throws {
        try self.graph.start()
    }
    
    fileprivate func stopGraph() throws {
        try self.graph.stop()
        self.onAudioInterruption?()
    }
    
    init() throws {
        let graph = try AudioUnitGraph<ManagedAudioUnitInstance>()
        self.graph = graph
        self.mixerNode = try self.graph.addNode(withDescription: .multiChannelMixer)
        self.outNode = try self.graph.addNode(withDescription: .defaultOutput)
        try self.mixerNode.connect(to: self.outNode!)
        try graph.open()
        let mixerinst = try self.mixerNode.getInstance()
        try mixerinst.setParameterValue(kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Output, element: 0, to: 1.0)
        try mixerinst.setProperty(withID: kAudioUnitProperty_MeteringMode, scope: kAudioUnitScope_Output, element: 0, to: UInt32(1))
        try graph.initialize()
        
        try self.setUpAudioRenderCallback()
        
//        try graph.start()
    }
    
    deinit {
//        AudioRemove
    }
    
    private func modifyingGraph(_ actions: (() throws ->())) throws {
        try stopGraph()
        try graph.uninitialize()
        try actions()
        try graph.initialize()
        try startGraph()
    }
    
    func clear() throws {
        try self.modifyingGraph {
            for ch in self.channels {
                for insert in ch._inserts {
                    try insert.disconnectAll()
                    try insert.removeFromGraph()
                }
                try ch.instrument?.disconnectAll()
                try ch.instrument?.removeFromGraph()
            }
            self.channels = []
            self.channelsChanged()
        }
    }
    
    /// add a Channel
    
    func add(channel: Channel) throws {
        let index = self.channels.count
        try self.modifyingGraph {
            try channel.headNode?.connect(element: 0, to: self.mixerNode, destElement: UInt32(index))
            try self.mixerNode._audioUnit?.setProperty(withID: kAudioUnitProperty_MeteringMode, scope: kAudioUnitScope_Input, element: UInt32(index), to: UInt32(1))
            try self.mixerNode.getInstance().setProperty(withID: kAudioUnitProperty_MeteringMode, scope: kAudioUnitScope_Output, element: 0, to: UInt32(1))
            channel.onHeadNodeChanged = { (_, _) in
                do {
                    try channel.headNode?.connect(element: 0, to: self.mixerNode, destElement: UInt32(index))
                    try self.mixerNode._audioUnit?.setProperty(withID: kAudioUnitProperty_MeteringMode, scope: kAudioUnitScope_Input, element: UInt32(index), to: UInt32(1))
                } catch {
                    fatalError("Failed to reconnect head node: \(error)")
                }
            }
            self.channels.append(channel)
            channel.audioSystem = self
            channel.index = index
            try self.mixerNode.getInstance().setParameterValue(kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Input, element: AudioUnitElement(index), to: 1.0)
            self.channelsChanged()
        }
        
    }
    
    /// Create a new Channel, with a default name and no inserts/instrument
    @discardableResult func createChannel() throws -> Channel {
        let channel = Channel(name: "ch\(self.channels.count+1)")
        try self.add(channel: channel)
        return channel
    }
    
    /// Look up a channel by name
    func channelNamed(_ name: String) -> Channel? {
        return self.channels.first(where: { $0.name == name })
    }
    
    //MARK: internal functions called from the channel
    fileprivate func getGain(forChannelIndex index: Int) throws -> AudioUnitParameterValue {
        return try self.mixerNode.getInstance().getParameterValue(kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Input, element: AudioUnitElement(index))
    }
    fileprivate func getPan(forChannelIndex index: Int) throws -> AudioUnitParameterValue {
        return try self.mixerNode.getInstance().getParameterValue(kMultiChannelMixerParam_Pan, scope: kAudioUnitScope_Input, element: AudioUnitElement(index))
    }
    fileprivate func setGain(forChannelIndex index: Int, to value: AudioUnitParameterValue) throws {
        return try self.mixerNode.getInstance().setParameterValue(kMultiChannelMixerParam_Volume, scope: kAudioUnitScope_Input, element: AudioUnitElement(index), to: value)
    }
    fileprivate func setPan(forChannelIndex index: Int, to value: AudioUnitParameterValue) throws {
        return try self.mixerNode.getInstance().setParameterValue(kMultiChannelMixerParam_Pan, scope: kAudioUnitScope_Input, element: AudioUnitElement(index), to: value)
    }
    
    //MARK: save/restore
    
    func snapshot() throws -> AudioSystemModel {
        return AudioSystemModel(channels: try self.channels.map { try $0.snapshot() })
    }
    
    func set(from snapshot: AudioSystemModel) throws {
        try self.clear()
        for ch in snapshot.channels {
            try self.add(channel: try Channel(graph: self.graph, snapshot: ch))
        }
    }
    
    //MARK: Recording
    
    typealias RecordingRenderCallback = (()->())
    
    /// a recording context, holding data through a recording process
    struct RecordingContext {
        let bufferListPtr: UnsafeMutableAudioBufferListPointer
        let recordingUnit: ManagedAudioUnitInstance
        var time: AudioTimeStamp = AudioTimeStamp()
        var trailingSilenceCounter: TrailingSilenceCounter = TrailingSilenceCounter(count: 0, threshold: 0.00003) /* <1/32768 */
        
        init(recordingUnit: ManagedAudioUnitInstance) {
            let numChannels = 2
            self.bufferListPtr = AudioBufferList.allocate(maximumBuffers: numChannels)
            self.recordingUnit = recordingUnit
            self.time.mFlags = AudioTimeStampFlags.sampleTimeValid
        }
    }
    
    private var recordingContext: RecordingContext? = nil
    
    /// Cause one frame to be rendered from within the recording function; this is kept private, and passed in a callback to the function.
    private func renderFrame() {
        guard var ctx = self.recordingContext else { fatalError("renderFrame() called with nil recordingContext") }
        do {
            try ctx.recordingUnit.render(timeStamp: ctx.time, numberOfFrames: numSamplesPerBuffer, data: &(ctx.bufferListPtr.unsafeMutablePointer.pointee))
            self.fileRecorder?.feed(ctx.bufferListPtr, numSamplesPerBuffer)
            self.recordingContext!.trailingSilenceCounter.feed(bufferList: ctx.bufferListPtr)
            self.recordingContext!.time.mSampleTime += Double(numSamplesPerBuffer)
        } catch {
            print("Error rendering frame: \(error)")
        }
    }
    
    // HACK: recorder
    var fileRecorder: AudioBufferConsumer? = nil
    
    /// The runout mode; what to do after the function running the recording process has completed.
    enum RecordingRunoutMode {
        /// No runout; cut off the recording immediately upon completion
        case none
        /// keep running until we get silence (S samples below the threshold) for a maximum number of buffers
        case toSilence(Int, Int)
    }
    
    func record(toConsumer consumer: (() throws -> AudioBufferConsumer), runoutMode: RecordingRunoutMode = .none, running function: (RecordingRenderCallback)->()) throws {
        try self.stopGraph()
        try self.graph.uninitialize()
        
        self.outputMode = .offlineRender

        try self.graph.initialize()

        // do the actual recording here
        
        let sourceNode = self.outNode!
        let outInst = try sourceNode.getInstance()
        
        self.fileRecorder = try consumer()
//        self.postRenderTap = recorder.feed
        self.recordingContext = RecordingContext(recordingUnit: outInst)
        
        function(self.renderFrame)

        switch(runoutMode) {
        case .none: break
        case .toSilence(let samples, let maxFrames):
            var trailingFrames: Int = 0
            while self.recordingContext?.trailingSilenceCounter.count ?? 0 < samples && trailingFrames < maxFrames {
                self.renderFrame()
                trailingFrames += 1
            }
            break
        }
//        self.postRenderTap = nil
        self.fileRecorder = nil
        try! self.graph.uninitialize()
        self.outputMode = .play
        try! self.graph.initialize()
        try! self.startGraph()
    }
    
    func record(toURL url: URL, runoutMode: RecordingRunoutMode = .none, running function: (RecordingRenderCallback)->()) throws {
        let makeRecorder = { () throws -> AudioBufferConsumer in
            let sourceNode = self.outNode!
            let outInst = try sourceNode.getInstance()
            let typeID: AudioFileTypeID = kAudioFileAIFFType // FIXME
            let asbd: AudioStreamBasicDescription = try outInst.getProperty(withID: kAudioUnitProperty_StreamFormat, scope: kAudioUnitScope_Global, element: 0)
    //        print("ASBD for default output: \(asbd)")
            return try AudioBufferFileRecorder(to: url, ofType: typeID, forStreamDescription: asbd)
        }
        try self.record(toConsumer: makeRecorder, running: function)
    }
    
    func record(to file: String, running function: (RecordingRenderCallback)->()) throws {
        try self.record(toURL: URL(fileURLWithPath: file), running: function)
    }
}


import Foundation

/** This handles the transport: the play position, tempo and such */
public class Metronome {
    public var tempo: Double = 120.0 {
        didSet {
            // 1 beat = 60.0/tempo
            self.tickDuration = (60.0/tempo) / Double(TickTime.ticksPerBeat)
            self.ticksPerSecond = 1/self.tickDuration
            self.onTempoChange?()
        }
    }
    public private(set) var tickDuration: TimeInterval = (60.0/120.0) / Double (TickTime.ticksPerBeat)
    private var ticksPerSecond: Double = 1 / ((60.0/120.0) / Double (TickTime.ticksPerBeat))
    
    /** The master tick time; in normal circumstances, this will be running constantly. This is not to be confused with the position in any current sequence/arrangement/program, which would be calculated from this and the running state. */
    public private(set) var tickTime: TickTime = 0
    
    /// the continuous tick time, calculated from the incoming frame time and the current tempo
    private var continuousTickTime: Double = 0
    
    //#MARK: notifications
    
    public var onTempoChange: (()->())?
    public var onGlobalRunningStateChange: (()->())?
    
    /// callbacks to be called every tick when the master transport is running
    public var onTick: [((TickTime)->())] = []
    
    ///MARK: Load monitoring
    
    // the numerator and denominator of the load value, in nanoseconds:
    private var loadRealTimeNS: UInt64 = 0
    private var loadRenderTimeNS: UInt64 = 0
    
    var load: Double {
        guard loadRenderTimeNS > 0 else { return 0.0 }
        defer {
            self.loadRealTimeNS = 0
            self.loadRenderTimeNS = 0
        }
        return Double(self.loadRealTimeNS) / Double(self.loadRenderTimeNS)
    }
    
    ///MARK:
    
    func advance(byFrames frames: Int, _ rate: Int) {
        let stime = mach_absolute_time()
        let elapsedNsec = UInt64(frames)*NSEC_PER_SEC / UInt64(rate)
        let elapsed = Double(frames)/Double(rate)
        let ticks = self.ticksPerSecond * elapsed
        let endTime = self.continuousTickTime + ticks
        if floor(endTime) > floor(self.continuousTickTime) {
            for t in (Int(ceil(self.continuousTickTime))..<Int(ceil(endTime))) {
                self.tickTime = TickTime(t)
                self.runForCurrentTick()
            }
        }
        self.loadRealTimeNS += convertToNanoseconds(fromMachTime: mach_absolute_time() - stime)
        self.loadRenderTimeNS += elapsedNsec
        self.continuousTickTime = endTime
    }

    
    /// Run for the current discrete tick
    private func runForCurrentTick() {
        for client in self.onTick {
            client(self.tickTime)
        }
    }
    
    //MARK: snapshotting
    func snapshot() -> MetronomeModel {
        return MetronomeModel(tempo: self.tempo)
    }
    
    func set(from model: MetronomeModel) {
        self.tempo = model.tempo
    }
}

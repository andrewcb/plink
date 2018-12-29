import Foundation

/** This handles the transport: the play position, tempo and such */
public class Metronome {
    public var tempo: Double = 120.0 {
        didSet {
            // 1 beat = 60.0/tempo
            self.tickDuration = (60.0/tempo) / Double(TickTime.ticksPerBeat)
            self.tickUsec = useconds_t(self.tickDuration*1000000)
            self.onTempoChange?()
        }
    }
    public private(set) var tickDuration: TimeInterval = (60.0/120.0) / Double (TickTime.ticksPerBeat)
    var tickUsec: useconds_t = useconds_t(((60.0/120.0) / Double (TickTime.ticksPerBeat)) * 1000000)
    
    /** The master tick time; in normal circumstances, this will be running constantly. This is not to be confused with the position in any current sequence/arrangement/program, which would be calculated from this and the running state. */
    public private(set) var masterTickTime: TickTime = 0
    
    
    private let dqueue = DispatchQueue(label: "metronome")
    
    //#MARK: notifications
    
    public var onTempoChange: (()->())?
    public var onGlobalRunningStateChange: (()->())?
    
    /// callbacks to be called every tick when the master transport is running
    public var onTick: [((TickTime)->())] = []
    
    // Mach timing
    var timebaseInfo = mach_timebase_info()
    
    public init() {
        guard mach_timebase_info(&self.timebaseInfo) == KERN_SUCCESS else { fatalError("Cannot get Mach timebase info?!")}
        self.masterRunning = true
        self.startMasterTransport()
    }

    /** Is the master transport running? */
    public var masterRunning: Bool = false {
        didSet(prev) {
            guard self.masterRunning != prev else { return }
            if self.masterRunning {
                self.startMasterTransport()
            } else {
            }
            self.onGlobalRunningStateChange?()
        }
    }
    
    private func startMasterTransport() {
        self.dqueue.async {
            
            while(self.masterRunning) {
                let start_time = mach_absolute_time()
                
                for client in self.onTick {
                    client(self.masterTickTime)
                }
                
                let elapsed_nsec = (mach_absolute_time() - start_time) * UInt64(self.timebaseInfo.numer) / UInt64(self.timebaseInfo.denom)
                let elapsed_usec = UInt32(elapsed_nsec / 1000)
                if elapsed_usec < self.tickUsec {
                    usleep(self.tickUsec - elapsed_usec)
                }
                self.masterTickTime += 1
            }
        }
    }

    func snapshot() -> MetronomeModel {
        return MetronomeModel(tempo: self.tempo)
    }
    
    func set(from model: MetronomeModel) {
        self.tempo = model.tempo
    }
}

//MARK: asynchronous execution for scripting purposes and such
extension Metronome {
    /**
     Executes code asynchronously within a tick time respective to the current tempo; this works whether or not the transport is running.
     */
    func async(inTicks ticks: TickDuration, execute closure: @escaping ()->Void) {
        Timer.scheduledTimer(withTimeInterval: self.tickDuration * Double(ticks.value), repeats: false, block: { _ in closure() })
    }
    
    /**
     Executes code asynchronously within a time in (possibly fractional) beats respective to the current tempo; this works whether or not the transport is running.
     */
    func async(inBeats beats: Double, execute closure: @escaping ()->Void) {
        let interval = beats * Double(TickDuration.ticksPerBeat) * self.tickDuration
        DispatchQueue.main.async {
            Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: { _ in closure() })
        }
    }
}

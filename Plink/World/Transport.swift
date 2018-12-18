import Foundation

/** This handles the transport: the play position, tempo and such */
public class Transport {
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
    
    /// The clock transmission state: i.e., how the clock gets converted to the program position, if at all
    enum TransmissionState {
        case stopped(TickTime)  // Stopped; the value is the tick time
        case starting(TickTime) // will start at the next tick from the given time
        case running(TickOffset) // pos = masterTickTime+offset
    }
    
    var transmissionState: TransmissionState = .stopped(0) {
        didSet(old) {
            print("transmissionState: \(old) -> \(self.transmissionState)")
        }
    }
    
    //MARK: Transmission copntrol
    public func startInPlace() {
        if case let .stopped(t) = self.transmissionState {
            self.transmissionState = .starting(t)
        }
    }
    
    public func rewindAndStart() {
        self.transmissionState = .starting(0)
    }
    
    public func stop() {
        self.transmissionState = .stopped(self.programPosition)
    }
    
    //MARK:
    
    /// The program position
    var programPosition: TickTime {
        switch(self.transmissionState) {
        case .stopped(let t): return t
        case .starting(let t): return t
        case .running(let offset): return self.masterTickTime + offset
        }
    }
    
    private let dqueue = DispatchQueue(label: "transport")
    
    //#MARK: notifications
    
    public var onTempoChange: (()->())?
    public var onRunningStateChange: (()->())?
    public var onGlobalRunningStateChange: (()->())?
    
    /// callbacks to be notified of a tick if the state is currently running
    public var onRunningTick: [((TickTime)->())] = []
    
    /// callbacks to be called every tick when the master transport is running
    public var onMasterTick: [((TickTime)->())] = []
    
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
                
                for client in self.onMasterTick {
                    client(self.masterTickTime)
                }

                if case let .starting(t) = self.transmissionState {
                    self.transmissionState = .running(t-self.masterTickTime)
                }
                if case let .running(offset) = self.transmissionState {
                    let pos = self.programPosition
                    for client in self.onRunningTick {
                        client(pos)
                    }
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

    func snapshot() -> TransportModel {
        return TransportModel(tempo: self.tempo)
    }
    
    func set(from model: TransportModel) {
        self.tempo = model.tempo
    }
}

//MARK: asynchronous execution for scripting purposes and such
extension Transport {
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

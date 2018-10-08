import Foundation

public protocol TransportClient {
    func runFor(time: TickTime)
}

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
    public private(set) var pos: TickTime = 0
    
    public var clients: [TransportClient] = []
    
    private let dqueue = DispatchQueue(label: "transport")
    
    // notifications
    public var onTempoChange: (()->())?
    public var onRunningStateChange: (()->())?

    // Mach timing
    var timebaseInfo = mach_timebase_info()
    
    public init() {
        guard mach_timebase_info(&self.timebaseInfo) == KERN_SUCCESS else { fatalError("Cannot get Mach timebase info?!")}
    }

    
    public var running: Bool = false {
        didSet(prev) {
            guard self.running != prev else { return }
            if self.running {
                self.start()
            } else {
            }
            self.onRunningStateChange?()
        }
    }
    
    private func start() {
        self.dqueue.async {
            
            while(self.running) {
                let start_time = mach_absolute_time()
                for client in self.clients {
                    client.runFor(time: self.pos)
                }
                
                let elapsed_nsec = (mach_absolute_time() - start_time) * UInt64(self.timebaseInfo.numer) / UInt64(self.timebaseInfo.denom)
                let elapsed_usec = UInt32(elapsed_nsec / 1000)
                if elapsed_usec < self.tickUsec {
                    usleep(self.tickUsec - elapsed_usec)
                }
                self.pos += 1
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
        Timer.scheduledTimer(withTimeInterval: beats * Double(TickDuration.ticksPerBeat) * self.tickDuration, repeats: false, block: { _ in closure() })
    }
}

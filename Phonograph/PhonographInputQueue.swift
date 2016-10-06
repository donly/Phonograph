import AudioToolbox
import Foundation

public typealias PhonographInputQueueCallback = (Data) -> Void

open class PhonographInputQueue {
    
    class PhonographInputQueueUserData {
        
        let callback: PhonographInputQueueCallback
        let bufferStub: Data
        
        init(callback: @escaping PhonographInputQueueCallback, bufferStub: Data) {
            self.callback = callback
            self.bufferStub = bufferStub
        }
    }
    
    fileprivate var audioQueueRef: AudioQueueRef? = nil
    
    fileprivate let userData: PhonographInputQueueUserData
        
    public init(asbd: AudioStreamBasicDescription, callback: @escaping PhonographInputQueueCallback, buffersCount: UInt32 = 3, bufferSize: UInt32 = 9600) throws {
        var asbd = asbd
        // TODO: Try to remove unwrap.
        self.userData = PhonographInputQueueUserData(callback: callback, bufferStub: NSMutableData(length: Int(bufferSize))! as Data)
        
        let userDataUnsafe = UnsafeMutableRawPointer(Unmanaged.passUnretained(self.userData).toOpaque())

        let code = AudioQueueNewInput(&asbd, audioQueueInputCallback, userDataUnsafe, nil, nil, 0, &audioQueueRef)
        
        if code != noErr {
            throw PhonographError.genericError(code)
        }
        
        for _ in 0..<buffersCount {
            var bufferRef: AudioQueueBufferRef? = nil
            
            let code = AudioQueueAllocateBuffer(audioQueueRef!, bufferSize, &bufferRef)
            
            if code != noErr {
                throw PhonographError.genericError(code)
            }
            
            // TODO: Probably call this only in start.
//            audioQueueInputCallback(userDataUnsafe, audioQueueRef!, bufferRef!, nil, 0, nil)
        }
    }
    
    deinit {
        do {
            try dispose()
        } catch {
            // TODO: Probably handle this exception.
        }
    }
    
    open func dispose() throws {
        let code = AudioQueueDispose(audioQueueRef!, true)
        
        if code != noErr {
            throw PhonographError.genericError(code)
        }
        
        audioQueueRef = nil
    }
    
    open func start() throws {
        let code = AudioQueueStart(audioQueueRef!, nil)
        
        if code != noErr {
            throw PhonographError.genericError(code)
        }
    }
    
    open func stop() throws {
        let code = AudioQueueStop(audioQueueRef!, true)
        
        if code != noErr {
            throw PhonographError.genericError(code)
        }
    }
    
    open func pause() throws {
        let code = AudioQueuePause(audioQueueRef!)
        
        if code != noErr {
            throw PhonographError.genericError(code)
        }
    }
        
    fileprivate let audioQueueInputCallback: AudioQueueInputCallback = { (inUserData, inAQ, inBuffer, inStartTime, inNumberPacketDescriptions, inPacketDescs) in
        
//        let PhonographInputQueueUserData = Unmanaged<PhonographInputQueueUserData>.fromOpaque(inUserData!).takeUnretainedValue()
//        
//        // TODO: Avoid cast.
//        let dataSize = Int(inBuffer.pointee.mAudioDataByteSize)
//        
//        let dataInputRaw = UnsafeMutablePointer<Int8>(inBuffer.pointee.mAudioData)
//        
//        // Think about avoiding unwrap. Usually this buffer will be always created. But...
//        let dataOutput = NSMutableData(length: dataSize)!
//        
//        let dataOutputRaw = UnsafeMutablePointer<Int8>(mutating: dataOutput.bytes.bindMemory(to: Int8.self, capacity: dataOutput.count))
//        
//        dataOutputRaw.assignFrom(dataInputRaw, count: dataSize)
//        
//        userData.callback(dataOutput as Data)
//        
//        // TODO: Handle error.
//        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)
    }
}

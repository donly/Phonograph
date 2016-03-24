import AudioToolbox
import Foundation

public typealias PhonographInputQueueCallback = (NSData) -> Void

public class PhonographInputQueue {
    
    class PhonographInputQueueUserData {
        
        let callback: PhonographInputQueueCallback
        let bufferStub: NSData
        
        init(callback: PhonographInputQueueCallback, bufferStub: NSData) {
            self.callback = callback
            self.bufferStub = bufferStub
        }
    }
    
    private var audioQueueRef: AudioQueueRef = nil
    
    private let userData: PhonographInputQueueUserData
        
    public init(var asbd: AudioStreamBasicDescription, callback: PhonographInputQueueCallback, buffersCount: UInt32 = 3, bufferSize: UInt32 = 9600) throws {
        // TODO: Try to remove unwrap.
        self.userData = PhonographInputQueueUserData(callback: callback, bufferStub: NSMutableData(length: Int(bufferSize))!)
        
        let userDataUnsafe = UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self.userData).toOpaque())

        let code = AudioQueueNewInput(&asbd, audioQueueInputCallback, userDataUnsafe, nil, nil, 0, &audioQueueRef)
        
        if code != noErr {
            throw PhonographError.GenericError(code)
        }
        
        for _ in 0..<buffersCount {
            var bufferRef = AudioQueueBufferRef()
            
            let code = AudioQueueAllocateBuffer(audioQueueRef, bufferSize, &bufferRef)
            
            if code != noErr {
                throw PhonographError.GenericError(code)
            }
            
            // TODO: Probably call this only in start.
            audioQueueInputCallback(userDataUnsafe, audioQueueRef, bufferRef, nil, 0, nil)
        }
    }
    
    deinit {
        do {
            try dispose()
        } catch {
            // TODO: Probably handle this exception.
        }
    }
    
    public func dispose() throws {
        let code = AudioQueueDispose(audioQueueRef, true)
        
        if code != noErr {
            throw PhonographError.GenericError(code)
        }
        
        audioQueueRef = nil
    }
    
    public func start() throws {
        let code = AudioQueueStart(audioQueueRef, nil)
        
        if code != noErr {
            throw PhonographError.GenericError(code)
        }
    }
    
    public func stop() throws {
        let code = AudioQueueStop(audioQueueRef, true)
        
        if code != noErr {
            throw PhonographError.GenericError(code)
        }
    }
    
    private let audioQueueInputCallback: AudioQueueInputCallback = { (inUserData, inAQ, inBuffer, inStartTime, inNumberPacketDescriptions, inPacketDescs) in
        let userData = Unmanaged<PhonographInputQueueUserData>.fromOpaque(COpaquePointer(inUserData)).takeUnretainedValue()
        
        // TODO: Avoid cast.
        let dataSize = Int(inBuffer.memory.mAudioDataByteSize)
        
        let dataInputRaw = UnsafeMutablePointer<Int8>(inBuffer.memory.mAudioData)
        
        // Think about avoiding unwrap. Usually this buffer will be always created. But...
        let dataOutput = NSMutableData(length: dataSize)!
        
        let dataOutputRaw = UnsafeMutablePointer<Int8>(dataOutput.bytes)
        
        dataOutputRaw.assignFrom(dataInputRaw, count: dataSize)
        
        userData.callback(dataOutput)
        
        // TODO: Handle error.
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)
    }
}
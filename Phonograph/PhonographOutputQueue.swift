import AudioToolbox
import Foundation

public typealias PhonographOutputQueueCallback = (bufferSizeMax: Int) -> NSData

public class PhonographOutputQueue {
    
    class PhonographOutputQueueUserData {
        
        let callback: PhonographOutputQueueCallback
        
        init(callback: PhonographOutputQueueCallback) {
            self.callback = callback
        }
    }
    
    private var audioQueueRef: AudioQueueRef = nil
    
    private let userData: PhonographOutputQueueUserData
        
    public init(var asbd: AudioStreamBasicDescription, callback: PhonographOutputQueueCallback, buffersCount: UInt32 = 3, bufferSize: UInt32 = 9600) throws {
        self.userData = PhonographOutputQueueUserData(callback: callback)
        
        let userDataUnsafe = UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self.userData).toOpaque())

        let code = AudioQueueNewOutput(&asbd, audioQueueOutputCallback, userDataUnsafe, nil, nil, 0, &audioQueueRef)
        
        if code != noErr {
            throw PhonographError.GenericError(code)
        }
        
        for _ in 0..<buffersCount {
            var bufferRef = AudioQueueBufferRef()
            
            let code = AudioQueueAllocateBuffer(audioQueueRef, bufferSize, &bufferRef)
            
            if code != noErr {
                throw PhonographError.GenericError(code)
            }
            
            audioQueueOutputCallback(userDataUnsafe, audioQueueRef, bufferRef)
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
        
    private let audioQueueOutputCallback: AudioQueueOutputCallback = { (inUserData, inAQ, inBuffer) in
        let userData = Unmanaged<PhonographOutputQueueUserData>.fromOpaque(COpaquePointer(inUserData)).takeUnretainedValue()
        
        // TODO: Think about cast.
        let capacity = Int(inBuffer.memory.mAudioDataBytesCapacity)
        
        let data = userData.callback(bufferSizeMax: capacity)

        let dataInputRaw = UnsafeMutablePointer<Int8>(data.bytes)
        
        let dataOutputRaw = UnsafeMutablePointer<Int8>(inBuffer.memory.mAudioData)
        
        dataOutputRaw.assignFrom(dataInputRaw, count: data.length)
        
        // TODO: Think about cast.        
        inBuffer.memory.mAudioDataByteSize = UInt32(data.length)
        
        // TODO: Handle error.
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)
    }
}
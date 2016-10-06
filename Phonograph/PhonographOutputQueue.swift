import AudioToolbox
import Foundation

public typealias PhonographOutputQueueCallback = (_ bufferSizeMax: Int) -> Data

open class PhonographOutputQueue {
    
    class PhonographOutputQueueUserData {
        
        let callback: PhonographOutputQueueCallback
        let bufferStub: Data
        
        init(callback: @escaping PhonographOutputQueueCallback, bufferStub: Data) {
            self.callback = callback
            self.bufferStub = bufferStub
        }
    }
    
    fileprivate var audioQueueRef: AudioQueueRef? = nil
    
    fileprivate let userData: PhonographOutputQueueUserData
        
    public init(asbd: AudioStreamBasicDescription, callback: @escaping PhonographOutputQueueCallback, buffersCount: UInt32 = 3, bufferSize: UInt32 = 9600) throws {
        var asbd = asbd
        // TODO: Try to remove unwrap.
        self.userData = PhonographOutputQueueUserData(callback: callback, bufferStub: NSMutableData(length: Int(bufferSize))! as Data)
        
        let userDataUnsafe = UnsafeMutableRawPointer(Unmanaged.passUnretained(self.userData).toOpaque())

        let code = AudioQueueNewOutput(&asbd, audioQueueOutputCallback, userDataUnsafe, nil, nil, 0, &audioQueueRef)
        
        if code != noErr {
            throw PhonographError.genericError(code)
        }
        
        for _ in 0..<buffersCount {
            var bufferRef: AudioQueueBufferRef? = nil
            
            let code = AudioQueueAllocateBuffer(audioQueueRef!, bufferSize, &bufferRef)
            
            if code != noErr {
                throw PhonographError.genericError(code)
            }
            
            audioQueueOutputCallback(userDataUnsafe, audioQueueRef!, bufferRef!)
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
        
    fileprivate let audioQueueOutputCallback: AudioQueueOutputCallback = { (inUserData, inAQ, inBuffer) in
        
        let userData = Unmanaged<PhonographOutputQueueUserData>.fromOpaque(inUserData!).takeUnretainedValue()
        
        // TODO: Think about cast.
        let capacity = Int(inBuffer.pointee.mAudioDataBytesCapacity)
        
        let dataFromCallback = userData.callback(capacity)

        // Audio queue will stop requesting buffers if output buffer will not contain bytes.
        // Use empty buffer filled with zeroes.
        let data = dataFromCallback.count > 0 ? dataFromCallback : userData.bufferStub
        
        let dataInputRaw = UnsafeMutablePointer<Int8>(mutating: (data as NSData).bytes.bindMemory(to: Int8.self, capacity: data.count))
        
        let dataOutputRaw = inBuffer.pointee.mAudioData.assumingMemoryBound(to: Int8.self)

        dataOutputRaw.assign(from: dataInputRaw, count: data.count)
        
        // TODO: Think about cast.        
        inBuffer.pointee.mAudioDataByteSize = UInt32(data.count)
        
        // TODO: Handle error.
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)
    }
}

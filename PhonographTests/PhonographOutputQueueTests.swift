import XCTest
@testable import Phonograph

class PhonographOutputQueueTests: XCTestCase {
    
    var asbd = AudioStreamBasicDescription()
    
    override func setUp() {
        super.setUp()

        asbd.mSampleRate = 8000;
        asbd.mFormatID = kAudioFormatLinearPCM
        asbd.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked | kLinearPCMFormatFlagIsNonInterleaved
        asbd.mBitsPerChannel = 16
        asbd.mChannelsPerFrame = 1
        asbd.mBytesPerFrame = asbd.mChannelsPerFrame * 2
        asbd.mFramesPerPacket = 1
        asbd.mBytesPerPacket = asbd.mFramesPerPacket * asbd.mBytesPerFrame
        asbd.mReserved = 0
    }
    
    private func outputQueueCallback(bufferSizeMax: Int) -> NSData {
        return NSData()
    }
    
    func testInitAndDeinit() {
        do {
            let _ = try PhonographOutputQueue(asbd: asbd, callback: outputQueueCallback)
        } catch {
            XCTFail("Output should be created successfully.")
        }
    }
    
    func testInitWithWrongAsbd() {
        let asbd = AudioStreamBasicDescription()
        
        do {
            let _ = try PhonographOutputQueue(asbd: asbd, callback: outputQueueCallback)
            
            XCTFail("Output should not be created successfully.")
        } catch PhonographError.GenericError(let code) {
            XCTAssertEqual(code, kAudio_ParamError)
        } catch {
            XCTFail("Unexpected exception.")
        }
    }
    
    func testInitDisposeAndDeinit() {
        do {
            let output = try PhonographOutputQueue(asbd: asbd, callback: outputQueueCallback)
            
            try output.dispose()
        } catch {
            XCTFail("Output should be created successfully.")
        }
    }
    
    func testInitAndDoubleDispose() {
        do {
            let output = try PhonographOutputQueue(asbd: asbd, callback: outputQueueCallback)
            
            try output.dispose()
            try output.dispose()
        } catch PhonographError.GenericError(let code) {
            XCTAssertEqual(code, kAudio_ParamError)
        } catch {
            XCTFail("Unexpected exception.")
        }
    }
}

import Foundation
import AVFoundation

class MicrophoneMonitor{
    
    private var audioRecorder: AVAudioRecorder
    private var currentSample: Int
    private let numberOfSamples: Int
    
    @Published public var soundSamples: [Float]
    
    init(numberOfSamples: Int) {
        self.numberOfSamples = numberOfSamples // In production check this is > 0.
        self.soundSamples = [Float](repeating: .zero, count: numberOfSamples)
        self.currentSample = 0
        
        // Create AVAudioSession and Check the Record Permission
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (isGranted) in
                if !isGranted {
                    fatalError("You must allow audio recording for this demo to work")
                }
            }
        }

        // SETUP RECORD SETTINGS where have to save the file later
        // cause we want to stream and not to save we send this to dev/null
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        let recorderSettings: [String:Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
        // Try to start recording
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            audioRecorder.isMeteringEnabled = true
            start_recording()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    // audio Recorder have to stop for the logouthandler
    func stop_recording(){
        audioRecorder.stop()
    }
    
    // starting audio recording
    func start_recording(){
        
        if (audioRecorder.isRecording){
            //print("Microphone is recording")
        }
        else{
            audioRecorder.record()
        }
        self.audioRecorder.updateMeters() // update Value from input
        self.soundSamples[self.currentSample] = self.audioRecorder.peakPower(forChannel: 0) // get Peak Value in db -160db to 0 db
        self.currentSample = (self.currentSample + 1) % self.numberOfSamples
        //move Sample to the limit
    }
    
    deinit {
        audioRecorder.stop()
    }
    
}

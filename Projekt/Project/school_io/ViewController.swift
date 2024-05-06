import UIKit
import AVKit //Audio Visual Library used for Camera
import Vision //Framefork used for Face Detection
import AVFoundation //used for Camera and Audio
import CoreLocation //GPS, Heading
import Speech //Noice detection



class ViewController: UIViewController {
    
    //GUI elements
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var camview: UIView!
    @IBOutlet weak var drawview: FaceView!
    @IBOutlet weak var eyeview: EyeView!
    @IBOutlet weak var DBLabel: UILabel!
    @IBOutlet weak var breaktimelabel: UILabel!
    @IBOutlet weak var examtimelabel: UILabel!
    @IBOutlet weak var userdisplay: UILabel!

    //init needed classes
    let locationManager = CLLocationManager()
    var sequenceHandler = VNSequenceRequestHandler()
    let avsession = AVCaptureSession()
    var av_layer: AVCaptureVideoPreviewLayer!
    let audioEngine = AVAudioEngine()
    var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    var recognitionTask: SFSpeechRecognitionTask?
    let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "de_DE"))! //recognize german language
    private var mic = MicrophoneMonitor(numberOfSamples: 1)
    private var timer:Timer!
    
    let dataOutputQueue = DispatchQueue( //Queue for Face Tracking
      label: "video data queue",
      qos: .userInitiated,
      attributes: [],
      autoreleaseFrequency: .workItem)

    //init Timer variables
    var BreakTimer: Timer!
    var totalBreakTime = 120
    var inabreak = false
    var ExamTimer: Timer!
    var totalExamTime = 100
    
    //init GPS variables
    var ismoving = 0
    var heading: CLLocationDirection!
    var newheading: CLLocationDirection!
    var checkheading = false
    var ischangeheading = 0
    
    //init ML enable, background enable, view variables
    var didchangetobackgroundagain = false
    var MLenable = false
    var talkingcounter = 0
    var maxX: CGFloat = 0.0
    var midY: CGFloat = 0.0
    var maxY: CGFloat = 0.0
    
    //starting view
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startExamTimer()
        DBLabel.text = "Please be quite and do not move while the exam!"
        userdisplay.text = "Name: " + name + "\n Studentnumber: " + snbr + "\n Exam: " + exmid
        breaktimelabel.text = "Break Time Left: " + String(totalBreakTime) + " sec"
        examtimelabel.text = "Exam Time Left: " + String(totalExamTime) + " min"
        //configure and setup functions
        configureCaptureSession()
        setupLocation()
    
        //set the geometry to show the face on right place
        maxX = drawview.bounds.maxX
        midY = drawview.bounds.midY
        maxY = drawview.bounds.maxY
        avsession.startRunning()
      
        mic.start_recording()
        let ms = 1000
        //sleep for handeling the problem of the audio output before
        usleep(useconds_t(1000 * ms))
        do {
            try configureSpeechSession()
        } catch {
                   print("Error! No Speech recording")
        }
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(startMonitoring), userInfo: nil, repeats: true)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil) //check if app moved to background
    }
    
    //check app in background twice
    @objc func appMovedToBackground() {
        if didchangetobackgroundagain == true{
            wasMovedToBackground()
        }else{
            didchangetobackgroundagain = true
        }
    }
    
    //Alert and failing exam when app was moved to background
    func wasMovedToBackground(){
        let alertController = UIAlertController(title: "Exam failed!", message:
                   "You have left the exam App!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: logouthandler))
        present(alertController, animated: true, completion: nil)
    }
    
}


// MARK: - Camera and Face tracking
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    //setup camera, get called every time when camera is able to capture a frame
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        //initialize video buffers for face tracking and ML face recognition
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        let pixelBuffer: CVPixelBuffer  = imageBuffer

        let detectFaceRequest = VNDetectFaceLandmarksRequest(completionHandler: detectedFace)

        //Face tracking
        do {
            try sequenceHandler.perform(
                [detectFaceRequest],
                on: imageBuffer,
                orientation: .leftMirrored)
            
            //Face recognition with ML, will start in second turn to prevent lag
            if(MLenable==true){
                MLenable=false
                mlcheckvalidation(pixelbuffer: pixelBuffer)
            }else{
                MLenable=true
            }
        } catch {
            print("Error! Face tracking did not work!")
        }
    }
}

// MARK: - Face detection and drawing
extension ViewController {
    
    //setup face tracking rect on our view
    func convert(rect: CGRect) -> CGRect {
        let origin = av_layer.layerPointConverted(fromCaptureDevicePoint: rect.origin)
        let size = av_layer.layerPointConverted(fromCaptureDevicePoint: rect.size.cgPoint)
        return CGRect(origin: origin, size: size.cgSize)
    }
    
    //setting draws on the layer
    func landmark(point: CGPoint, to rect: CGRect) -> CGPoint {
        let absolute = point.absolutePoint(in: rect)
        let converted = av_layer.layerPointConverted(fromCaptureDevicePoint: absolute)
        return converted
    }

    //Function to set points of face
    func landmark(points: [CGPoint]?, to rect: CGRect) -> [CGPoint]? {
        guard let points = points else {
            return nil
        }
        return points.compactMap { landmark(point: $0, to: rect) }
    }
  
    //drawing and update the Face
    func updateFaceView(for result: VNFaceObservation) {
        defer {
            DispatchQueue.main.async { //be in main thread
                //to draw in drawview
                self.drawview.setNeedsDisplay()
            }
        }

        let box = result.boundingBox
        drawview.boundingBox = convert(rect: box)

        guard let landmarks = result.landmarks else {return}

        if let leftEye = landmark(
            points: landmarks.leftEye?.normalizedPoints,
            to: result.boundingBox) {
            drawview.leftEye = leftEye
        }

        if let rightEye = landmark(
            points: landmarks.rightEye?.normalizedPoints,
            to: result.boundingBox) {
            drawview.rightEye = rightEye
        }

        if let leftEyebrow = landmark(
            points: landmarks.leftEyebrow?.normalizedPoints,
            to: result.boundingBox) {
            drawview.leftEyebrow = leftEyebrow
        }

        if let rightEyebrow = landmark(
            points: landmarks.rightEyebrow?.normalizedPoints,
            to: result.boundingBox) {
            drawview.rightEyebrow = rightEyebrow
        }

        if let nose = landmark(
            points: landmarks.nose?.normalizedPoints,
            to: result.boundingBox) {
            drawview.nose = nose
        }

        if let outerLips = landmark(
            points: landmarks.outerLips?.normalizedPoints,
            to: result.boundingBox) {
            drawview.outerLips = outerLips
        }

        if let innerLips = landmark(
            points: landmarks.innerLips?.normalizedPoints,
            to: result.boundingBox) {
            drawview.innerLips = innerLips
        }

        if let faceContour = landmark(
            points: landmarks.faceContour?.normalizedPoints,
            to: result.boundingBox) {
            drawview.faceContour = faceContour
        }
    } //end of func updateFaceView

    func detectedFace(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNFaceObservation],
              let result = results.first
        else {
            //if there is no face -> clear the view
            drawview.clear()
            return
        }
        
        updateFaceView(for: result)
        updateeyeView(for: result)
    }
    
    //drawing and update the Eye
    func updateeyeView(for result: VNFaceObservation) {
        
        eyeview.clear()
        
        //cheching users views/eye by head direction
        let yaw = result.yaw ?? 0.0
        if yaw == 0.0 {
            return
        }
        
        var origins: [CGPoint] = []

        if let point = result.landmarks?.leftPupil?.normalizedPoints.first {
            let origin = landmark(point: point, to: result.boundingBox)
            origins.append(origin)
        }
        
        if let point = result.landmarks?.rightPupil?.normalizedPoints.first {
            let origin = landmark(point: point, to: result.boundingBox)
            origins.append(origin)
        }
        
        let avgY = origins.map { $0.y }.reduce(0.0, +) / CGFloat(origins.count)
        let focusY = (avgY < midY) ? 0.75 * maxY : 0.25 * maxY
        let focusX = (yaw.doubleValue > 0.0) ? -100.0 : maxX + 100.0
        let focus = CGPoint(x: focusX, y: focusY)
        
        for origin in origins {
            let eye = Eye(origin: origin, focus: focus)
            eyeview.add(Eye: eye)
        }

        DispatchQueue.main.async { //main thread
            self.camview.setNeedsDisplay()
            
        }
    }

}
// MARK: - Video Processing methods
extension ViewController {
    
    func configureCaptureSession() {
        // Define the capture device we want to use
        guard let av_device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                               for: .video,
                                               position: .front) else{return}
        av_device.isFocusModeSupported(.continuousAutoFocus)
        guard let av_input = try? AVCaptureDeviceInput(device: av_device) else{return}
        avsession.addInput(av_input)
        let av_dataoutput = AVCaptureVideoDataOutput()
        av_dataoutput.setSampleBufferDelegate(self, queue: dataOutputQueue) //"VideoQueue"
        av_dataoutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        avsession.addOutput(av_dataoutput)
        let videoConnection = av_dataoutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait

        // Configure the layers
        av_layer = AVCaptureVideoPreviewLayer(session: avsession)
        av_layer.videoGravity = .resizeAspectFill
        camview.layer.addSublayer(av_layer)
        av_layer.frame = camview.bounds
        camview.layer.insertSublayer(av_layer, at: 0) //added subview to draw facebox
    }
}

// MARK: - Timer with Pause and Exam End Buttons
extension ViewController {
    
    @objc func updateExamTime() {
        //countdown of the varibale
        if totalExamTime != 1 {
            totalExamTime -= 1
            examtimelabel.text = "Exam Time Left: " + String(totalExamTime) + " min"
        }else{
            let alertController = UIAlertController(title: "Exam finished!", message:
                       "The time is over! Submitted your Exam!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: logouthandler))
            present(alertController, animated: true, completion: nil)
            ExamTimer.invalidate() //pause the timer to prevent negative timer
        }
    }

    //start or stop pause timer by pressing the pause button
    @IBAction func pausebutton(_ sender: UIButton) {
        if inabreak != true{
            sender.setTitle("Continue", for: .normal)
            startBreakTimer()
            inabreak = true
        }else{
            sender.setTitle("Pause", for: .normal)
            stopBreakTimer()
            inabreak = false
        }
    }
  
    //Submitting exam if the student wants it
    @IBAction func examendbutton(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Do you really want to submit your exam?", message:
                 "Your attempt will be ended!", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "No", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: logouthandler))
        self.present(alertController, animated: true, completion: nil)
    }

    //starting Timer, counting in seconds
    func startBreakTimer() {
        BreakTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateBreakTime), userInfo: nil, repeats: true)
    }
    
    //counting in minutes (60 sec)
    func startExamTimer() {
        ExamTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(updateExamTime), userInfo: nil, repeats: true)
    }

    //invalidate break timer when the student is back of his/her break
    func stopBreakTimer() {
        BreakTimer.invalidate()
    }
    
    @objc func updateBreakTime() {
        if totalBreakTime != 0 {
            totalBreakTime -= 1
            breaktimelabel.text = "Break Time Left: " + String(totalBreakTime) + " sec"
        }else{
            let alertController = UIAlertController(title: "Exam Failed!", message:
                       "Your break time is over!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: logouthandler))
            present(alertController, animated: true, completion: nil)
            label.text = "Exam Finished"
            examtimelabel.text = "Exam Time Left: 0 min"
            totalExamTime = 0
            BreakTimer.invalidate()
        }
    }

    //Handler when exam finished, sets all values back to default, goes to the login view
    func logouthandler(alert: UIAlertAction!){
        label.text = "Exam Finished"
        breaktimelabel.text = "Break Time Left: 0 sec"
        examtimelabel.text = "Exam Time Left: 0 min"
        totalBreakTime = 0
        totalExamTime = 0
        ismoving = 0
        totalExamTime = 10
        checkheading = false
        didchangetobackgroundagain = false
        ischangeheading = 0
        talkingcounter = 0
        //stopping sessions
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
        timer.invalidate()
        mic.stop_recording()
        avsession.stopRunning()
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        //go to login view
        performSegue(withIdentifier: "seguetologin", sender: self)
    }
    
}
// MARK: - ML DATA COMPARE
extension ViewController {
    
    //get called when camera captured a frame to recognize the students face
    func mlcheckvalidation(pixelbuffer: CVPixelBuffer) {
        //calling our created ML
        guard let our_model = try? VNCoreMLModel(for: ourML().model) else {return}
        
        //creating handler for perform request
        let model_request = VNCoreMLRequest(model: our_model){(finishedReq, err) in
            //Classification information produced by an image analysis request = VNClassificationObservation
            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
            guard let firstobservation = results.first else {return}
            DispatchQueue.main.async { //main thread, print identification and confidence of recognized person
                self.label.text = String(firstobservation.identifier) + " : " + String(format: "%.2f", firstobservation.confidence * 100) + "%"
            }
        }
        //image analysis against ML, this will be done at first
        try? VNImageRequestHandler(cvPixelBuffer: pixelbuffer, options: [:]).perform([model_request])
    }
}

// MARK: - GPS
extension ViewController: CLLocationManagerDelegate{
    
    func setupLocation(){
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            locationManager.distanceFilter = 50
            if(CLLocationManager.headingAvailable()){
                locationManager.headingFilter = 10
                locationManager.startUpdatingHeading()
            }
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        //check if old heading is different then the new heading
        if(checkheading == false){
            checkheading = true
            heading = newHeading.magneticHeading
        }else{
            checkheading = false
            newheading = newHeading.magneticHeading
            if newheading != heading{
                //counter for tolerance
                ischangeheading = ischangeheading + 1
                if (ischangeheading == 3){ //first alerting
                    let alertController = UIAlertController(title: "Do not move your Phone!", message:
                               "You are moving your Phone! Please let it in one place!", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .default))
                    present(alertController, animated: true, completion: nil)
                }
                if(ischangeheading > 5){ //while doing -> Exam fails
                    let alertController = UIAlertController(title: "Exam Failed!", message:
                               "You are still moving your Phone!", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: logouthandler))
                    present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let _ = locations.first{
            //checking speed of the device to prevent moving
            var speed: CLLocationSpeed = CLLocationSpeed()
            speed = locationManager.location!.speed
            speed = speed * 3.6 //mps to km/h
            if(speed > 6.0){
                //counter for tolerance
                ismoving = ismoving + 1
                if (ismoving == 3){
                    let alertController = UIAlertController(title: "Do not move!", message:
                               "You are moving! Please stay in one place!", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .default))
                    present(alertController, animated: true, completion: nil)
                }
            }
            if(ismoving > 5){ //while moving -> Exam fails
                let alertController = UIAlertController(title: "Exam Failed!", message:
                           "You are still moving!", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: logouthandler))
                present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        //check status of location access of the device -> open settings
        if status == CLAuthorizationStatus.denied{
            let alertController = UIAlertController(title: "GPS access disabled!", message:
                       "Need GPS Access!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            alertController.addAction(openAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
}

// MARK: - Speech recognition
extension ViewController: SFSpeechRecognizerDelegate {
    
    //setup speech recognition
    func configureSpeechSession() throws {
        recognitionTask?.cancel()
        self.recognitionTask = nil
        
        speechRecognizer.delegate = self
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object") }
        recognitionRequest.shouldReportPartialResults = true
        
        //recognizing speech
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
        var isFinal = false
        
            if let result = result {
                isFinal = result.isFinal
                //printing the recognized speech out of the buffer
                print("Text: \(result.bestTranscription.formattedString)")
    
                self.talkingcounter = self.talkingcounter + 1
                if(self.talkingcounter % 2 == 0) {
                    if self.audioEngine.isRunning {
                        //stopping mic to prevent buffor overflow, siri fail and alert fail
                        self.audioEngine.stop()
                    }
                    let alertController = UIAlertController(title: "Please stop talking!", message:
                               "Be quite while the exam!", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Okay", style: .default, handler: self.startaudioagain))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            
            // Stop recognizing speech if there is a problem
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 8192, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
    }
    
    //check if recognizer is available
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            print("Speech available")
        } else {
            print("Speech not available")
        }
    }
    
    //Handler to start audio again
    func startaudioagain(alert: UIAlertAction!){
        do {
            try audioEngine.start()
        } catch {
            print("Error! No Speech recording")
        }
    }
    
}

// MARK: - Microphone Noise Tracking
extension ViewController {
    @objc func startMonitoring() {
        mic.start_recording()
        //calculate dB of the noise tracked by the microphone
        let db1 = 20 * log10(5 * powf(10, (mic.soundSamples.first!/20)) * 160) + 35
        //let db2 = 20 * (log10(5) + mic.soundSamples.first!/20 + log10(160)) + 35
        if (db1 > 95.0) { // later the maximum tolerance is between 40db-50db
            let alertController = UIAlertController(title: "There is to much noise!", message:
                       "Please be quite during the exam!", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Okay", style: .default))
            present(alertController, animated: true, completion: nil)
        }

        DispatchQueue.main.async { //main thread
            self.DBLabel.text = String(format: "%.2f ", db1) + "db"
        }
    }
}

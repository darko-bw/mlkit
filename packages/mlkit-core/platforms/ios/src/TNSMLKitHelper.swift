import Foundation
import AVFoundation
import MLKit

#if canImport(MLKitBarcodeScanning)
import MLKitBarcodeScanning
#endif

#if canImport(MLKitFaceDetection)
import MLKitFaceDetection
#endif

#if canImport(MLKitTextRecognition)
import MLKitTextRecognition
#endif

#if canImport(MLKitDigitalInkRecognition)
import MLKitDigitalInkRecognition
#endif

#if canImport(MLKitImageLabeling)
import MLKitImageLabeling
#endif

#if canImport(MLKitObjectDetection)
import MLKitObjectDetection
#endif

#if canImport(MLKitPoseDetection)
import MLKitPoseDetection
#endif



@objc(TNSMLKitHelperCameraPosition)
public enum TNSMLKitHelperCameraPosition: Int, RawRepresentable {
    case Front
    case Back
    public typealias RawValue = UInt32
    
    public var rawValue: RawValue {
        switch self {
        case .Back:
            return 0
        case .Front:
            return 1
        }
    }
    
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case 0:
            self = .Back
        case 1:
            self = .Front
        default:
            return nil
        }
    }
    
    
    public init?(string: String) {
        switch string {
        case "back":
            self = .Back
        case "front":
            self = .Front
        default:
            return nil
        }
    }
    
}


struct TNSBounds: Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}


func createBounds(_ frame: CGRect) -> TNSBounds {
    return TNSBounds(x: Double(frame.origin.x), y: Double(frame.origin.y), width: Double(frame.size.width), height: Double(frame.size.height))
}


struct TNSPoint: Codable {
    var x:Double
    var y: Double
}

func createPoint(_ point: NSValue?) -> TNSPoint? {
    guard point != nil else {return nil}
    return  TNSPoint(x: Double(point!.cgPointValue.x), y: Double(point!.cgPointValue.y))
}


func createPoints(_ points: [NSValue]?) -> [TNSPoint]? {
    guard points != nil else {return nil}
    var results: [TNSPoint] = []
    for point in points! {
        results.append(createPoint(point)!)
    }
    return results
}




@objc(TNSMLKitDetectionType)
enum TNSMLKitDetectionType: Int, RawRepresentable {
    case Barcode
    case DigitalInk
    case Face
    case Image
    case Object
    case Pose
    case Text
    case All
    case None
    public typealias RawValue = UInt32
    
    public var rawValue: RawValue {
        switch self {
        case .Barcode:
            return 0
        case .DigitalInk:
            return 1
        case .Face:
            return 2
        case .Image:
            return 3
        case .Object:
            return 4
        case .Pose:
            return 5
        case .Text:
            return 6
        case .All:
            return 7
        case .None:
            return 8
        }
    }
    
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case 0:
            self = .Barcode
        case 1:
            self = .DigitalInk
        case 2:
            self = .Face
        case 3:
            self = .Image
        case 4:
            self = .Object
        case 5:
            self = .Pose
        case 6:
            self = .Text
        case 7:
            self = .All
        case 8:
            self = .None
        default:
            return nil
        }
    }
    
    
    public init?(string: String) {
        switch string {
        case "barcode":
            self = .Barcode
        case "digitalInk":
            self = .DigitalInk
        case "face":
            self = .Face
        case "image":
            self = .Image
        case "object":
            self = .Object
        case "pose":
            self = .Pose
        case  "text":
            self = .Text
        case "all":
            self = .All
        case "none":
            self = .None
        default:
            return nil
        }
    }
    
    func string() -> String {
        switch(self){case .Barcode:
            return "barcode"
        case .DigitalInk:
            return "digitalInk"
        case .Face:
            return "face"
        case .Image:
            return "image"
        case .Object:
            return "object"
        case .Pose:
            return "pose"
        case .Text:
            return "text"
        case .All:
            return "all"
        case .None:
            return "none"
        }
    }
}


@objc(TNSMLKitHelper)
@objcMembers
public class TNSMLKitHelper: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onScanCallback: ((String, String) -> Void)?
    var onError: ((NSError) -> Void)?
    private var _output = AVCaptureVideoDataOutput()
    let queue = DispatchQueue(label: "TNSMLKitHelper")
    let sessionQueue = DispatchQueue(label: "TNSMLKitHelperSession")
    private var isSessionSetup = false
    private var videoInput: AVCaptureDeviceInput?
    var cameraPosition = TNSMLKitHelperCameraPosition.Back {
        didSet {
            if(!isSessionSetup){
                return
            }
            setCamera()
        }
    }
    var output: AVCaptureVideoDataOutput {
        get {
            return _output
        }
    }
    let session = AVCaptureSession()
    let encoder = JSONEncoder()
    var detectorType = TNSMLKitDetectionType.All
    
    
#if canImport(MLKitBarcodeScanning)
    var barcodeScanner: BarcodeScanner?
#endif
    
    
#if canImport(MLKitFaceDetection)
    var faceDetector: FaceDetector?
#endif
    
    
#if canImport(MLKitTextRecognition)
    var textRecognizer: TextRecognizer?
#endif
    
    
#if canImport(MLKitDigitalInkRecognition)
    var digitalInkRecognizer: DigitalInkRecognizer?
#endif
    
    
#if canImport(MLKitImageLabeling)
    var imageLabeler: ImageLabeler?
#endif
    
    
#if canImport(MLKitObjectDetection)
    var objectDetector: ObjectDetector?
#endif
    
    
#if canImport(MLKitPoseDetection)
    var poseDetector: PoseDetector?
#endif
    
    
    
    
    public override init() {
        super.init()
        _output.alwaysDiscardsLateVideoFrames = true
        _output.videoSettings = [
            String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        _output.setSampleBufferDelegate(self, queue: queue)
    }
    
    public func startPreview(){
        sessionQueue.async {
            if(self.isSessionSetup && !self.session.isRunning){
                self.session.startRunning()
            }
        }
        
    }
    
    public func stopPreview(){
        sessionQueue.async {
            if(self.isSessionSetup && self.session.isRunning){
                self.session.stopRunning()
            }
        }
    }
    
    public func toggleCamera(){
        if cameraPosition == .Front {
            cameraPosition = .Back
        }else {
            cameraPosition = .Front
        }
        setCamera()
    }
    private func setCamera(){
        sessionQueue.async {
            if(self.isSessionSetup){
                let wasRunning = self.session.isRunning
                
                let videoDevice = self.getVideoDevice()
                guard videoDevice != nil else {
                    let error = NSError(domain: "Failed to toggleCamera", code: 1, userInfo: nil)
                    self.onError?(error)
                    return
                }
                
                let videoInput: AVCaptureDeviceInput?
                do {
                    videoInput = try AVCaptureDeviceInput(device: videoDevice!)
                } catch {
                    self.onError?(error as NSError)
                    return
                }
                
                
                if(wasRunning){
                    self.session.stopRunning()
                }
                
                
                if(self.videoInput != nil){
                    self.session.removeInput(self.videoInput!)
                }
                
                self.videoInput = videoInput
                
                if(self.session.canAddInput(videoInput!)){
                    self.session.addInput(videoInput!)
                }
                if(wasRunning){
                    self.session.startRunning()
                }
            }
        }
    }
    
    private func getVideoDevice() -> AVCaptureDevice? {
        var captureDevice: AVCaptureDevice?
        var position = AVCaptureDevice.Position.back
        if self.cameraPosition == .Front {
            position = .front
        }
        if #available(iOS 10.0, *){
            captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
            
        }else {
            let devices = AVCaptureDevice.devices(for: .video)
            for device in devices {
                if device.position == position {
                    captureDevice = device
                    break
                }
            }
        }
        return captureDevice
    }
    
    public func openCamera(){
        sessionQueue.async {
            if(self.isSessionSetup){
                return
            }
            let captureDevice = self.getVideoDevice()
            guard captureDevice != nil else {return}
            do {
                self.videoInput = try AVCaptureDeviceInput(device: captureDevice!)
            }catch {
                self.onError?(error as NSError)
            }
            
            guard self.videoInput != nil else {return}
            
            self.session.beginConfiguration()
            self.session.addInput(self.videoInput!)
            
            if self.session.canAddOutput(self.output){
                self.session.addOutput(self.output)
            }
            self.session.commitConfiguration()
            self.isSessionSetup = true
            
        }
    }
    
    private func handleNil(_ value: AnyObject?) -> AnyHashable {
        guard value != nil else {return NSNull()}
        return value as! AnyHashable
    }
    
    
    private func handleNilArray(_ value: [Any]?) -> Any {
        guard value != nil else {return NSNull()}
        return value!
    }
    
    
    func toJSON<T: Encodable>(_ value: T)-> String?{
        do{
            let json = try encoder.encode(value)
            return String(data: json, encoding: .utf8) ?? nil
        }catch{
            return nil
        }
    }
    
    
    
    func getOrientation(deviceOrientation: UIDeviceOrientation, cameraPosition: AVCaptureDevice.Position) -> UIImage.Orientation {
        switch (deviceOrientation) {
        case .portrait:
            if cameraPosition == .front {
                return .leftMirrored
            }
            return .right
            
        case .landscapeLeft:
            if cameraPosition == .front {
                return .downMirrored
            }
            return .up
        case .portraitUpsideDown:
            if cameraPosition == .front {
                return .rightMirrored
            }
            return .left
        case .landscapeRight:
            if cameraPosition == .front {
                return .upMirrored
            }
            return .down
        case .unknown, .faceUp, .faceDown:
            return .up;
        }
    }
    
    
    
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        autoreleasepool {
            let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            guard buffer != nil else {return}
            let image = VisionImage(buffer: sampleBuffer)
            
            image.orientation = getOrientation(deviceOrientation: UIDevice.current.orientation, cameraPosition: videoInput!.device.position)
            
            
#if canImport(MLKitBarcodeScanning)
            if(detectorType == .Barcode || detectorType == .All){
                do {
                    let result = try self.barcodeScanner?.results(in: image)
                    if(result != nil){
                        let barCodes = handleBarcodeScanner(result!)
                        if(!barCodes.isEmpty) {
                            let response = toJSON(barCodes)
                            if(response != nil){
                                onScanCallback?(response!, TNSMLKitDetectionType.Barcode.string())
                            }
                        }
                    }
                } catch {}
            }
#endif
            
            
#if canImport(MLKitFaceDetection)
            if(detectorType == .Face || detectorType == .All){
                do {
                    let result = try self.faceDetector?.results(in: image)
                    if(result != nil){
                        let faces = handleFaceDetection(result!)
                        
                        if(!faces.isEmpty) {
                            let response = toJSON(faces)
                            if response != nil {
                                onScanCallback?(response!, TNSMLKitDetectionType.Face.string())
                            }
                        }
                    }
                } catch {}
            }
#endif
            
            
            
#if canImport(MLKitPoseDetection)
            if(detectorType == .Pose || detectorType == .All){
                do {
                    let result = try self.poseDetector?.results(in: image)
                    if(result != nil){
                        let poses = handlePoseDetection(result!)
                        
                        if(!poses.isEmpty) {
                            let response = toJSON(poses)
                            if response != nil {
                                onScanCallback?(response!, TNSMLKitDetectionType.Pose.string())
                            }
                        }
                    }
                } catch {}
            }
#endif
            
            
            
#if canImport(MLKitImageLabeling)
            if(detectorType == .Image || detectorType == .All){
                do {
                    let result = try self.imageLabeler?.results(in: image)
                    if(result != nil){
                        let labels = handleImageLabeling(result!)
                        
                        if(!labels.isEmpty) {
                            let response = toJSON(labels)
                            if response != nil {
                                onScanCallback?(response!, TNSMLKitDetectionType.Image.string())
                            }
                        }
                    }
                } catch {}
            }
#endif
            
            
            
#if canImport(MLKitObjectDetection)
            if(detectorType == .Object || detectorType == .All){
                do {
                    let result = try self.objectDetector?.results(in: image)
                    if(result != nil){
                        let objects = handleObjectDetection(result!)
                        
                        if(!objects.isEmpty) {
                            let response = toJSON(objects)
                            if response != nil {
                                onScanCallback?(response!, TNSMLKitDetectionType.Object.string())
                            }
                        }
                    }
                } catch {}
            }
#endif
            
            
            
            
#if canImport(MLKitTextRecognition)
            if(detectorType == .Text || detectorType == .All){
                do {
                    let result = try self.textRecognizer?.results(in: image)
                    if(result != nil){
                        let texts = handleTextRecognition(result!)
                        
                        if(!texts.isEmpty) {
                            let response = toJSON(texts)
                            if response != nil {
                                onScanCallback?(response!, TNSMLKitDetectionType.Text.string())
                            }
                        }
                    }
                } catch {}
            }
#endif
            
        }
        
    }
    
}
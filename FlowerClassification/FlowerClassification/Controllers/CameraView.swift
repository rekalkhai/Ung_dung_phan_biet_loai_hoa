//
//  CameraViewController.swift
//  FlowerClassification
//
//  Created by Khanh Vu on 30/03/5 Reiwa.
//

//
//  ViewController.swift
//  IntergrateMLModel
//
//  Created by Khanh Vu on 24/03/5 Reiwa.
//

import UIKit
import SnapKit
import AVFoundation
import CoreMotion
import Vision
import Photos
enum OutputType {
    case video
    case photo
    case portrait
}

protocol CameraViewDelegate: AnyObject {
//    func btnCancelTapped()
    func didShowAlertSetting(title: String, message: String)
    func didShowAlert(title: String, message: String)
    func didCapturedImage(imageCaptured: UIImage)
    func btnLibraryTapped()
    func didCaptureFrameVideo(cvPixel: CVPixelBuffer)
}

// Custom camera view
class CameraView: UIView {
    
    // Khai báo biến
    var session: AVCaptureSession!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var photoOutput : AVCapturePhotoOutput!
    var videoOutput: AVCaptureVideoDataOutput!
    var videoDeviceInput: AVCaptureDeviceInput!
    
    var outputType = OutputType.photo
    var flash: AVCaptureDevice.FlashMode = .off
    private var isCapture = false
    private let sessionQueue = DispatchQueue(label: "session queue")// Communicate with the session and other session objects on this queue.
    private var setupResult: SessionSetupResult = .success
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera], mediaType: .video, position: .unspecified)
    private var lastTimestamp = CMTime.zero
    private var framesPerSecond: Double = 2
    lazy var vPreviewVideo: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 15
        v.layer.masksToBounds = true
        v.backgroundColor = UIColor(hexString: "#242121")
        return v
    }()
    
    private var vOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.layer.borderWidth = 1.5
        v.layer.borderColor = UIColor.orange.cgColor
        return v
    }()
    
    private lazy var btnSwitchCamera: UIButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(btnSwitchcameraTapped), for: .touchUpInside)
        btn.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        btn.tintColor = .white
        return btn
    }()
    
    private lazy var btnCapture: CustomCaptureButton = {
        let vCapture = CustomCaptureButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        vCapture.btn.addTarget(self, action: #selector(didTapCaptureImage), for: .touchUpInside)
        return vCapture
    }()
    
//    private lazy var btnCancel: UIButton = {
//        let btn = UIButton()
//        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
//        btn.tintColor = .white
//        btn.addTarget(self, action: #selector(btnCancelTapped), for: .touchUpInside)
//        return btn
//    }()
    
    private lazy var btnFlash: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(btnFlashTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var btnLibrary: UIButton = {
        let btn = UIButton()
        btn.addConnerRadius(radius: 10)
        btn.addBorder(borderWidth: 2, borderColor: .white)
        btn.addTarget(self, action: #selector(btnLibraryTapped), for: .touchUpInside)
        return btn
    }()
    
    weak var delegate: CameraViewDelegate?
    init(cameraType: OutputType) {
        super.init(frame: .zero)
        self.outputType = cameraType
        self.checkPermissions()
        self.configView()
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    // Set up giao diện
    func configView() {
        self.backgroundColor = UIColor(hexString: "#242121")
        [self.vPreviewVideo, self.btnSwitchCamera, self.btnFlash, self.btnCapture, self.btnLibrary].forEach { subView in
            self.addSubview(subView)
        }
        self.vPreviewVideo.snp.makeConstraints { make in
            if outputType == .portrait {
                make.height.equalTo(self.snp.width).multipliedBy(Double(4.0/3.0))
            } else {
                make.height.equalTo(self.snp.width).multipliedBy(Double(1920.0/1080.0))
            }
            make.centerX.equalToSuperview()
            make.top.equalTo(self.snp.top)
            make.leading.trailing.equalToSuperview().inset(5)
        }
//        self.btnCancel.snp.makeConstraints { make in
//            make.top.equalToSuperview().offset(10)
//            make.width.height.equalTo(40)
//            make.leading.equalToSuperview().offset(20)
//        }
        self.btnSwitchCamera.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.width.height.equalTo(40)
            make.trailing.equalTo(self.snp.centerX).offset(-10)
        }
        self.btnFlash.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.width.height.equalTo(40)
            make.leading.equalTo(self.snp.centerX).offset(10)
        }
        self.btnCapture.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.height.equalTo(60)
            if outputType == .portrait {
                make.top.equalTo(self.vPreviewVideo.snp.bottom).offset(40)
            } else {
                make.bottom.equalTo(self.vPreviewVideo.snp.bottom).offset(-40)
            }
        }
        self.btnLibrary.snp.makeConstraints { make in
            make.width.height.equalTo(60)
            make.centerY.equalTo(self.btnCapture.snp.centerY)
            make.leading.equalToSuperview().offset(20)
        }
        self.fetchFirstAssets {[weak self] image in
            DispatchQueue.main.async {
                self?.btnLibrary.setBackgroundImage(image, for: .normal)
            }
        }
        
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        self.addGestureRecognizer(pinchGesture)
    }
    
    // Set up phiên camera
    private func configureSession() {
        if setupResult != .success {
            return
        }
        self.session = AVCaptureSession()
        self.session.beginConfiguration()
        self.session.sessionPreset = .photo
        
        // Add input.
        self.setUpCamera()

        //Add ouput
        switch outputType {
        case .video:
            self.setupVideoOutput()
        default:
            self.setUpPhotoOutput()
        }
        
        // Add preview
        DispatchQueue.main.async {
            self.setUpPreviewLayer()
        }
        self.session.commitConfiguration()
    }
    
    // Bắt đầu phiên camera
    func startSession() {
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
            case .notAuthorized:
                DispatchQueue.main.async {
                    self.delegate?.didShowAlertSetting(title: "App", message: "App doesn't have permission to use the camera, please change privacy settings")
                }
            case .configurationFailed:
                DispatchQueue.main.async {
                    self.delegate?.didShowAlert(title: "App", message: "Unable to capture media")
                }
            }
        }
        
    }
    
    // Dừng phiên camera
    func stopSession() {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.session = nil
            }
        }
    }
    
    // Kiểm tra quyền truy cập camera
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
        }
    }
    
    
    // Add camera vào sesion
    func setUpCamera() {
        do {
            var defaultVideoDevice: AVCaptureDevice?
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            switch outputType {
            case .portrait:
                guard let backCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) else {
                    self.delegate?.didShowAlertSetting(title: "App", message: "No Camera Portrait!")
                    return
                }
                defaultVideoDevice = backCameraDevice
            default :
                if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                    // If the back dual camera is not available, default to the back wide angle camera.
                    self.session.sessionPreset = .hd1920x1080
                    defaultVideoDevice = backCameraDevice
                } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                    defaultVideoDevice = frontCameraDevice
                }
            }

            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice!)
            if self.session.canAddInput(videoDeviceInput) {
                self.session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                //                DispatchQueue.main.async {
                //                    /*
                //                        Why are we dispatching this to the main queue?
                //                        Because AVCaptureVideoPreviewLayer is the backing layer for PreviewView and UIView
                //                        can only be manipulated on the main thread.
                //                        Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                //                        on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                //
                //                        Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
                //                        handled by CameraViewController.viewWillTransition(to:with:).
                //                    */
                //                    let statusBarOrientation = UIApplication.shared.statusBarOrientation
                //                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                //                    if statusBarOrientation != .unknown {
                //                        if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: statusBarOrientation) {
                //                            initialVideoOrientation = videoOrientation
                //                        }
                //                    }
                //
                //                    self.previewLayer.connection?.videoOrientation = initialVideoOrientation
                //                }
            } else {
                print("Could not add video device input to the session")
                setupResult = .configurationFailed
                self.session.commitConfiguration()
                return
            }
        } catch {
            print("Could not create video device input: \(error)")
            self.setupResult = .configurationFailed
            self.session.commitConfiguration()
            return
        }
    }
    
    //MARK: Set up output
    func setUpPreviewLayer() {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        self.previewLayer.videoGravity = .resizeAspectFill
        self.vPreviewVideo.layer.insertSublayer(self.previewLayer, above: self.vPreviewVideo.layer)
        self.previewLayer.frame = self.vPreviewVideo.bounds
        self.vPreviewVideo.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapHandleFocus)))
    }
    
    // Setup output khi ở mode video
    func setupVideoOutput(){
        self.videoOutput = AVCaptureVideoDataOutput()
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        self.videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        if self.session.canAddOutput(self.videoOutput) {
            self.session.addOutput(self.videoOutput)
        } else {
            print("could not add video output")
            self.setupResult = .configurationFailed
            self.session.commitConfiguration()
        }
        self.videoOutput.connections.first?.videoOrientation = .portrait
    }
    
    // Setup output khi ở mode photo
    func setUpPhotoOutput() {
        self.photoOutput = AVCapturePhotoOutput()
        if self.session.canAddOutput(self.photoOutput) {
            self.session.addOutput(self.photoOutput)
            self.photoOutput.isHighResolutionCaptureEnabled = true
            self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported
            self.photoOutput.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
        } else {
            print("Could not add photo output to the session")
            self.setupResult = .configurationFailed
            self.session.commitConfiguration()
            return
        }
    }
    
    //MARK: @objc func
    var zoomCamera = 1.0
    // Xử lí zoom camera
    @objc func handlePinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
        let camera = self.videoDeviceInput.device
        if gestureRecognizer.state == .began {
            print("began")
        } else if gestureRecognizer.state == .changed {
            do {
                try camera.lockForConfiguration()
                let scale = gestureRecognizer.scale
                var zoomFactor = 0.0
                if scale < 1 && self.zoomCamera > 1{
                    zoomFactor = self.zoomCamera * scale
                } else {
                    zoomFactor = self.zoomCamera * scale
                }
                zoomFactor = max(1.0, min(zoomFactor, 10))
                camera.videoZoomFactor = zoomFactor
                camera.unlockForConfiguration()
            }catch {
                print(error)
            }
        } else {
            self.zoomCamera = camera.videoZoomFactor
        }
 
    }
    
    // xử lí khi tap focus camera
    @objc func tapHandleFocus(_ gestureRecognizer: UITapGestureRecognizer) {
        let point = gestureRecognizer.location(in: gestureRecognizer.view)
        self.addSquareWhenTapFocus(point: point)
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
        focus(with: .autoFocus, exposureMode: .autoExpose, at: devicePoint, monitorSubjectAreaChange: true)
        
    }
    
//    @objc func btnCancelTapped() {
//        self.delegate?.btnCancelTapped()
//    }
    
    // Xử lí khi bật tắt flash
    @objc func btnFlashTapped() {
        switch self.outputType {
        case .video:
            let device = self.videoDeviceInput.device
            guard device.isTorchAvailable else { return }
            do {
                try device.lockForConfiguration()
                if device.torchMode == .off {
                    self.btnFlash.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
                    device.torchMode = .on
                    try device.setTorchModeOn(level: 0.7)
                } else {
                    self.btnFlash.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
                
            } catch {
                debugPrint(error)
            }
        default:
            if flash == .off {
                self.btnFlash.setImage(UIImage(systemName: "bolt.fill"), for: .normal)
                flash = .on
            } else {
                self.btnFlash.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)
                flash = .off
            }
        
        }
        
    }
    
    // Xử lí khi đổi camera trước sau
    @objc func btnSwitchcameraTapped() {
        sessionQueue.async {
            let currentVideoDevice = self.videoDeviceInput.device
            let currentPosition = currentVideoDevice.position
            
            let preferredPosition: AVCaptureDevice.Position
            let preferredDeviceType: AVCaptureDevice.DeviceType
            
            switch currentPosition {
            case .unspecified, .front:
                preferredPosition = .back
                preferredDeviceType = .builtInDualCamera
                
            case .back:
                preferredPosition = .front
                preferredDeviceType = .builtInWideAngleCamera
            }
            
            let devices = self.videoDeviceDiscoverySession.devices
            var newVideoDevice: AVCaptureDevice? = nil
            
            // First, look for a device with both the preferred position and device type. Otherwise, look for a device with only the preferred position.
            if let device = devices.first(where: { $0.position == preferredPosition && $0.deviceType == preferredDeviceType }) {
                newVideoDevice = device
            } else if let device = devices.first(where: { $0.position == preferredPosition }) {
                newVideoDevice = device
            }
            
            if let videoDevice = newVideoDevice {
                do {
                    let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                    
                    self.session.beginConfiguration()
                    
                    // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
                    self.session.removeInput(self.videoDeviceInput)
                    
                    if self.session.canAddInput(videoDeviceInput) {
                        self.session.addInput(videoDeviceInput)
                        self.videoDeviceInput = videoDeviceInput
                    } else {
                        self.session.addInput(self.videoDeviceInput)
                    }
                    switch self.outputType {
                    case .video:
                        self.videoOutput.connections.first?.videoOrientation = .portrait
                    default:
                        self.photoOutput.isLivePhotoCaptureEnabled = self.photoOutput.isLivePhotoCaptureSupported
                        self.photoOutput.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliverySupported
                    }
                    self.session.commitConfiguration()
                } catch {
                    print("Error occured while creating video device input: \(error)")
                }
            }
        }
    }
    
    // Xử lí khi nhấn vào nút chụp ảnh
    @objc func didTapCaptureImage() {
        print("capture")
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
            self.btnCapture.layer.borderWidth = 10
            
        } completion: { _ in
            self.btnCapture.layer.borderWidth = 6
        }
        switch self.outputType {
        case .video:
            self.isCapture = true
        default:
            DispatchQueue.main.async {
                let photoSettings = AVCapturePhotoSettings()
                photoSettings.flashMode = self.flash
                self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
            }
        }
    }
    
    // Xử lí khi nhấn vào nút mở thư viện
    @objc func btnLibraryTapped() {
        self.delegate?.btnLibraryTapped()
    }
    
    // Xử lí chức năng focus
    private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
        
}

extension CameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
        // Xử lí đầu ra là các frame của của mode video
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // Lấy ra các frame từ video
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let timeDifference = timestamp - lastTimestamp
        let frameRate = Double(Double(CMTimeScale(timestamp.timescale)) / timeDifference.seconds)
        if frameRate >= framesPerSecond {
            // Process the frame here
            guard let cvPixel = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }
            
            // Bắn các Frame qua FilterViewController để xử lí
            self.delegate?.didCaptureFrameVideo(cvPixel: cvPixel)
            if self.isCapture {
                self.isCapture = false
                var img: UIImage?
                switch self.videoDeviceInput.device.position {
                case .front :
                    img = convertToFlipImage(pixelBuffer: cvPixel)
                default:
                    img = convertToUIImage(pixelBuffer: cvPixel)
                }
                guard let img = img else {
                    return
                }
                // Bắn hình ảnh Được chụp qua FilterViewcontroller để xử lí
                self.delegate?.didCapturedImage(imageCaptured: img)
            }
            lastTimestamp = timestamp
        }
    }
}

extension CameraView: AVCapturePhotoCaptureDelegate {
    
    // Xử lí ouput của mode chụp ảnh
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        guard let capturedImage = UIImage(data: imageData)  else {
            return
        }
        var img: UIImage!
        switch self.videoDeviceInput.device.position {
        case .back :
            img = capturedImage
        default:
            img = UIImage(cgImage: capturedImage.cgImage!, scale: capturedImage.scale, orientation: .leftMirrored)
        }
        self.delegate?.didCapturedImage(imageCaptured: img)
    }
}

extension CameraView {
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    // Thêm animation hình vuông focus khi tap vào màn hình camera
    func addSquareWhenTapFocus(point: CGPoint) {
        self.vOverlay.transform = .identity
        self.vOverlay.removeFromSuperview()
        self.addSubview(self.vOverlay)
        self.vOverlay.snp.makeConstraints { make in
            make.width.height.equalTo(100)
            make.centerX.equalTo(point.x)
            make.centerY.equalTo(point.y)
        }
        UIView.animate(withDuration: 0.2) {
            self.vOverlay.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.vOverlay.removeFromSuperview()
            self.vOverlay.transform = .identity
        }
    }
    
    // Các function đối type để xử lí
    func convertToUIImage(pixelBuffer: CVPixelBuffer) -> UIImage? {
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cameraImage = context.createCGImage(image, from: image.extent) else { return nil }
        return UIImage(cgImage: cameraImage)
    }
    
    func convertToFlipImage(pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        // Tạo CIContext để chuyển đổi CIImage thành CGImage
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            // Tạo UIImage từ CGImage
            let uiImage = UIImage(cgImage: cgImage)
            // Đảo chiều ảnh
            let flippedImage = UIImage(cgImage: uiImage.cgImage!, scale: uiImage.scale, orientation: .upMirrored)
            return flippedImage
        }
        return nil
    }
    
    // Lấy hình ảnh đầu tiên trong thư viện
    func fetchFirstAssets(completion: @escaping (UIImage?)->Void)  {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        DispatchQueue.global(qos: .background).async {
            guard let result = PHAsset.fetchAssets(with: options).firstObject else {
                completion(nil)
                return
            }
            let key = "thumbnailFirst-\(result.localIdentifier)"
            if let cachedImage = ImageCache.shared.image(forKey: key) {
                completion(cachedImage)
            } else {
                let imageManager = PHImageManager.default()
                let thumbnailOptions = PHImageRequestOptions()
                thumbnailOptions.deliveryMode = .fastFormat
                thumbnailOptions.resizeMode = .exact
                thumbnailOptions.isNetworkAccessAllowed = false
                thumbnailOptions.isSynchronous = true
                imageManager.requestImage(for: result, targetSize: self.btnLibrary.frame.size, contentMode: .aspectFill, options: thumbnailOptions) { (image, info) in
                    guard let image = image else {
                        completion(nil)
                        return
                    }
                    completion(image)
                    ImageCache.shared.setImage(image, forKey: key)
                }
            }
        }
    }
}

// Lưu hình ảnh vào cache
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    
    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    func image(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
}

//
//  FilterViewController.swift
//  IntergrateMLModel
//
//  Created by Khanh Vu on 26/03/5 Reiwa.
//

import UIKit
import SnapKit
import AVFoundation
import Vision

protocol CameraProtocol: NSObject {
    func didSendImageCaptured(image: UIImage)
}
class FilterViewController: UIViewController {
    
    // khai báo label hiển thị tên của loài hoa
    private lazy var lbIdentifier: UILabel = {
        let lb = UILabel()
        lb.textColor = .white
        lb.font = UIFont.boldSystemFont(ofSize: 20)
        lb.text = "Identifier"
        lb.textAlignment = .center
        return lb
    }()
    
    // khai báo label hiển thị độ tin cậy
    private lazy var lbConfidence: UILabel = {
        let lb = UILabel()
        lb.textColor = .white
        lb.font = UIFont.boldSystemFont(ofSize: 20)
        lb.text = "Confidence"
        lb.textAlignment = .center
        return lb
    }()
    private lazy var stvLabel: UIStackView = {
        let stv = UIStackView()
        [lbIdentifier, lbConfidence].forEach { sub in
            stv.addArrangedSubview(sub)
        }
        stv.distribution = .fillEqually
        stv.axis = .vertical
        stv.alignment = .center
        stv.spacing = 10
        
        return stv
    }()
    private var cameraView: CameraView!
    private var detailView: DetailImageView!
    weak var delegate: CameraProtocol?
    private var imagePicker = UIImagePickerController()

    private var coremlRequest: VNCoreMLRequest?
    
    // chuyển đổi tên tiếng anh sang tiếng việt
    let dataDict = ["daisy": "Hoa Cúc Trắng", "dandelion": "Hoa Bồ Công Anh", "roses": "Hoa Hồng", "sunflowers": "Hoa Hướng Dương", "tulips": "Hoa Tulip"]
    var isCaptured = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUpView()
        predict()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.cameraView.startSession()
       
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.cameraView.stopSession()
    }
    
    // set up view hiển thị
    func setUpView() {
        self.view.backgroundColor = UIColor(hexString: "#242121")
        self.cameraView = CameraView(cameraType: .video)
        self.cameraView.delegate = self
        self.cameraView.isHidden = false
        self.detailView = DetailImageView()
        self.detailView.delegate = self
        self.detailView.isHidden = true
        [cameraView, detailView, stvLabel].forEach { sub in
            self.view.addSubview(sub)
        }
        cameraView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.leading.equalTo(self.view.snp.leading)
            make.trailing.equalTo(self.view.snp.trailing)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        detailView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.leading.equalTo(self.view.snp.leading)
            make.trailing.equalTo(self.view.snp.trailing)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        stvLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(60)
        }
        
    }
    
    // load model flower classification và thực hiện xử lí khi có kết quả trả về
    private func predict() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            
            // load model với VNCoreMLModel
            guard let model = try? VNCoreMLModel(for: Flowers_classification(configuration: MLModelConfiguration()).model) else {
                fatalError("Model initilation failed!")
            }
            // tạo request
            let coremlRequest = VNCoreMLRequest(model: model) { [weak self] request, error in
                guard let self = self else {
                    return
                }
                DispatchQueue.main.async {
                    if let results = request.results {
                        // handle khi có kết quả trả về
                        self.handleRequest(results)
                    }
                }
            }
            coremlRequest.imageCropAndScaleOption = .scaleFill
            self?.coremlRequest = coremlRequest
        }
    }
    
    // func xử lí kết quả trả về sau khi nhận diện ảnh
    func handleRequest(_ results: [Any]) {
        if let results = results as? [VNClassificationObservation] {
            print("\(results.first!.identifier) : \(results.first!.confidence)")
            let name = dataDict[results.first!.identifier]
            
            // check nếu confidence < 0.7 thì hiển thị unknow còn nếu >= 0.7 hiển thị ra identifier và confidence của kết quả đó
            if  results.first!.confidence < 0.7 {
                DispatchQueue.main.async {
                    self.lbIdentifier.text = "Unkown"
                    self.lbConfidence.text = ""
                }
            } else {
                DispatchQueue.main.async {
                    self.lbIdentifier.text = name
                    self.lbConfidence.text = "\(results.first!.confidence)"
                }
            }
        }
    }
    
}
extension FilterViewController: CameraViewDelegate {
    func didShowAlert(title: String, message: String) {
        self.showAlert(title: title, message: message)
    }
    
    func didShowAlertSetting(title: String, message: String) {
        self.showAlertSetting(title: title, message: message)
    }
    
    // xử lí nhận diện hình ảnh bằng model khi chụp từ camera
    func didCapturedImage(imageCaptured: UIImage) {
        DispatchQueue.main.async {
            self.detailView.configImage(image: imageCaptured)
            self.isCaptured = true
            self.detailView.isHidden = false
            self.cameraView.isHidden = true
            DispatchQueue.global().sync {
                guard let coremlRequest = self.coremlRequest else {
                    return
                }
                // request handle image
                let bufferImage = VNImageRequestHandler(cgImage: imageCaptured.cgImage!, options: [:])
                
                do {
                    try bufferImage.perform([coremlRequest])
                } catch {
                    print("cant perform predict: ", error)
                }
            }
        }
    }
    
    // xử lí khi chọn mở thư viện
    func btnLibraryTapped() {
        self.imagePicker.delegate = self
        self.imagePicker.sourceType = .photoLibrary
        self.isCaptured = true
        // hiển thị view thư viện ảnh
        present(imagePicker, animated: true, completion: nil)
    }
    
    // Xử lí nhận diện hình ảnh bằng model từ  các Frame được lấy ra từ camera realtime
    func didCaptureFrameVideo(cvPixel: CVPixelBuffer) {
        if !isCaptured {
            DispatchQueue.global().sync {
                guard let coremlRequest = self.coremlRequest else {
                    return
                }
                let bufferImage = VNImageRequestHandler(cvPixelBuffer: cvPixel, options: [:])
                
                do {
                    try bufferImage.perform([coremlRequest])
                } catch {
                    print("cant perform predict: ", error)
                }
            }
        }
    }
    
}

extension FilterViewController: DetailImageViewProtocol {
    func btnSendImageTapped(image: UIImage) {
        self.delegate?.didSendImageCaptured(image: image)
        self.dismiss(animated: true)
    }
    
    func btnCancelImageTapped() {
        self.detailView.isHidden = true
        self.cameraView.isHidden = false
        self.isCaptured = false
    }
    
    func btnDownloadTapped() {
        print("down")
    }

}
extension FilterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Xử lí khi chọn hình ảnh từ thư viện
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let img = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        guard let image = img else {
            return
        }
        
        // hiển thị ra màn hình
        self.detailView.configImage(image: image)
        self.detailView.isHidden = false
        self.cameraView.isHidden = true
        // xử lí nhận diện bằng model
        DispatchQueue.global().sync {
            guard let coremlRequest = self.coremlRequest else {
                return
            }
            let bufferImage = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
            
            do {
                try bufferImage.perform([coremlRequest])
            } catch {
                print("cant perform predict: ", error)
            }
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    // xử lí khi nhấn nút Cancel để tắt mằn hình thư viện
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        self.isCaptured = false
    }
}


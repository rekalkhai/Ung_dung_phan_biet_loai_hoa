//
//  DetailImageViewController.swift
//  IntergrateMLModel
//
//  Created by Khanh Vu on 07/04/5 Reiwa.
//

import UIKit
import SnapKit

protocol DetailImageViewProtocol: NSObject {
    func btnCancelImageTapped()
    func btnDownloadTapped()
    func btnSendImageTapped(image: UIImage)
}

// custom để hiển thị hình ảnh chi tiết
class DetailImageView: UIView {

    private lazy var imvDetail: UIImageView = {
        let imv = UIImageView()
        imv.contentMode = .scaleAspectFit
        return imv
    }()
    
    // Khai báo nút Back về màn trước đó
    private lazy var btnCancel: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(btnCancelImageTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var btnDownload: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(systemName: "arrow.down.to.line.compact"), for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(btnDownloadTapped), for: .touchUpInside)
        btn.isHidden = true
        return btn
    }()
    
    private lazy var btnSendImage: UIButton = {
        let btn = UIButton()
        btn.setTitle("Send", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.backgroundColor = .white
        btn.addConnerRadius(radius: 10)
        btn.isHidden = true
        btn.addTarget(self, action: #selector(btnSendImageTapped), for: .touchUpInside)
        return btn
    }()
    
    
    private lazy var vContent: UIView = {
        let v = UIView()
        [imvDetail, btnCancel, btnDownload].forEach { sub in
            v.addSubview(sub)
        }
        v.layer.cornerRadius = 15
        v.layer.masksToBounds = true
        v.backgroundColor = .white
        return v
    }()
    
    weak var delegate: DetailImageViewProtocol?
    
    init() {
        super.init(frame: .zero)
        self.setUpView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Set up giao diện
    func setUpView() {
        self.backgroundColor = UIColor(hexString: "#242121")
        [vContent, btnSendImage].forEach { sub in
            self.addSubview(sub)
        }
        self.vContent.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(5)
            make.height.equalTo(self.vContent.snp.width).multipliedBy(Double(1920.0/1080.0))
        }
        self.imvDetail.snp.makeConstraints { make in
            make.top.leading.trailing.bottom.equalToSuperview()
        }
        self.btnCancel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.width.height.equalTo(40)
            make.leading.equalToSuperview().offset(20)
        }
        self.btnDownload.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.width.height.equalTo(40)
            make.trailing.equalToSuperview().offset(-20)
        }
        self.btnSendImage.snp.makeConstraints { make in
            make.top.equalTo(self.vContent.snp.bottom).offset(10)
            make.trailing.equalToSuperview().offset(-15)
            make.height.equalTo(40)
            make.width.equalTo(50)
            make.bottom.lessThanOrEqualToSuperview()
        }
    }
    
    func configImage(image: UIImage) {
        self.imvDetail.image = image
    }
    
    @objc func btnCancelImageTapped() {
        delegate?.btnCancelImageTapped()
    }
    
    @objc func btnDownloadTapped() {
        delegate?.btnDownloadTapped()
    }
    
    @objc func btnSendImageTapped() {
        delegate?.btnSendImageTapped(image: self.imvDetail.image!)
    }
}

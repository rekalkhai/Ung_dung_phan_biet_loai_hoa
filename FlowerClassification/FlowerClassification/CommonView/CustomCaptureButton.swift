//
//  CustomCaptureButton.swift
//  IntergrateMLModel
//
//  Created by Khanh Vu on 29/03/5 Reiwa.
//

import UIKit
import SnapKit
class CustomCaptureButton: UIView {

    let btn = UIButton()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView(frame: frame)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setUpView(frame: CGRect) {
        self.addSubview(btn)
        
        btn.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.width.height.equalToSuperview().offset(2)
        }
        self.layer.cornerRadius = frame.width/2
        self.layer.borderWidth = 6
        self.layer.borderColor = UIColor.black.cgColor
//        self.layer.masksToBounds = true
        self.backgroundColor = .white
        
        btn.layer.cornerRadius = frame.width/2
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor.white.cgColor
        btn.backgroundColor = .clear
//        btn.layer.masksToBounds = true
    }
    

}

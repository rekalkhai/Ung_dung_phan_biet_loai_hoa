//
//  UIView+Extensions.swift
//  FlowerClassification
//
//  Created by Khanh Vu on 14/04/5 Reiwa.
//

import Foundation
import UIKit
extension UIView {
    func addBorder(borderWidth: CGFloat, borderColor: UIColor ) {
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
    }
    
    func addShadow(color: UIColor = .black, opacity: Float = 1.0, radius: CGFloat = 0.0, offset: CGSize = CGSize.zero) {
        layer.shadowColor = color.cgColor
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.shadowOffset = offset
        layer.masksToBounds = false
    }
    
    func addConnerRadius(radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
//    func convertToString(timestamp: Timestamp, formatter: String? = "hh:mm") -> String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = formatter
//        let date = Date(timeIntervalSince1970: TimeInterval(timestamp.seconds))
////        let date = timestamp // replace with your own Firestore Date object
//        let dateString = dateFormatter.string(from: date)
//        return dateString
//    }
}

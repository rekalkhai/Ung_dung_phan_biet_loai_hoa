////
////  File.swift
////  ChatApp
////
////  Created by Vu Khanh on 14/03/2023.
////
//
import Foundation
import UIKit

//extension UIImageView {
//    open override func layoutSubviews() {
//        super.layoutSubviews()
//        if let image = self.image {
//            let imageRatio = image.size.width / image.size.height
//            self.frame.size = CGSize(width: self.frame.width, height: self.frame.width * imageRatio)
//        }
//    }
//}
extension UIImage {
    func rotate(_ radians: CGFloat) -> UIImage {
      let cgImage = self.cgImage!
      let LARGEST_SIZE = CGFloat(max(size.width, size.height))
      let context = CGContext(data: nil, width: Int(LARGEST_SIZE), height: Int(LARGEST_SIZE), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue)!

      var drawRect = CGRect.zero
      drawRect.size = size
      let drawOrigin = CGPoint(x: (LARGEST_SIZE - size.width) * 0.5, y: (LARGEST_SIZE - size.height) * 0.5)
      drawRect.origin = drawOrigin
      var tf = CGAffineTransform.identity
      tf = tf.translatedBy(x: LARGEST_SIZE * 0.5, y: LARGEST_SIZE * 0.5)
      tf = tf.rotated(by: CGFloat(radians))
      tf = tf.translatedBy(x: LARGEST_SIZE * -0.5, y: LARGEST_SIZE * -0.5)
      context.concatenate(tf)
      context.draw(cgImage, in: drawRect)
      var rotatedImage = context.makeImage()!

      drawRect = drawRect.applying(tf)

      rotatedImage = rotatedImage.cropping(to: drawRect)!
      let resultImage = UIImage(cgImage: rotatedImage)
      return resultImage
    }

}

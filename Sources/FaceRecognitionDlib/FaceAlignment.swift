//
//  Alignment.swift
//
//
//  Created by Jakub Dolejs on 18/03/2025.
//

import Foundation
import Accelerate
import simd
import UIKit
import VerIDCommonTypes
import DlibLandmarks

class FaceAlignment {
    
    let landmarkDetector: DlibLandmarks
    
    init() throws {
        guard let predictorPath = Bundle.module.path(forResource: "shape_predictor_5_face_landmarks", ofType: "dat") else {
            throw FaceRecognitionError.modelFileNotFound("shape_predictor_5_face_landmarks.dat")
        }
        self.landmarkDetector = DlibLandmarks(modelAtPath: predictorPath)
    }
    
    func alignFaces(_ faces: [Face], inImage image: Image) throws -> [UIImage] {
        let size: Int = 150
        let grayscaleBuffer = try image.toGrayscale()
        guard let cgImage = image.toCGImage() else {
            throw FaceRecognitionError.imageConversionFailure
        }
        return try faces.map { face in
            do {
                let t = try self.landmarkDetector.faceChipTransform(forGrayscale: grayscaleBuffer, width: Int32(cgImage.width), height: Int32(cgImage.height), faceRect: face.bounds, size: Int32(size), padding: 0.25)
                let a  = CGFloat(truncating: t[0])
                let b  = CGFloat(truncating: t[1])
                let tx = CGFloat(truncating: t[2])
                let c  = CGFloat(truncating: t[3])
                let d  = CGFloat(truncating: t[4])
                let ty = CGFloat(truncating: t[5])
                
                let s = CGFloat(cgImage.height)
                let h = CGFloat(size)
                
                let ap  =  a
                let bp  = -b
                let txp =  tx + b * (s - 1)
                let cp  = -c
                let dp  =  d
                let typ = (h - 1) - ty - d * (s - 1)
                
                let Aup = CGAffineTransform(a: ap, b: cp, c: bp, d: dp, tx: txp, ty: typ)
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1.0
                return UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format).image { ctx in
                    ctx.cgContext.interpolationQuality = .high
                    ctx.cgContext.translateBy(x: 0, y: h)
                    ctx.cgContext.scaleBy(x: 1, y: -1)
                    ctx.cgContext.concatenate(Aup)
                    ctx.cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
                }
            } catch {
                throw FaceRecognitionError.faceAlignmentFailure(error)
            }
        }
    }
}

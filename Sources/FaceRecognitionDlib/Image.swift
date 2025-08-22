//
//  Image.swift
//  
//
//  Created by Jakub Dolejs on 21/08/2025.
//

import Foundation
import Accelerate
import VerIDCommonTypes
import CoreVideo

extension Image {
    
    func toGrayscale() throws -> [UInt8] {
        let w = width, h = height
        guard CVPixelBufferGetPixelFormatType(videoBuffer) == kCVPixelFormatType_32BGRA else {
            throw FaceRecognitionError.imageConversionFailure
        }
        
        CVPixelBufferLockBaseAddress(videoBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(videoBuffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(videoBuffer) else {
            throw FaceRecognitionError.imageConversionFailure
        }
        
        var src = vImage_Buffer(data: base,
                                height: vImagePixelCount(h),
                                width:  vImagePixelCount(w),
                                rowBytes: CVPixelBufferGetBytesPerRow(videoBuffer))
        
        var gray = [UInt8](repeating: 0, count: w * h)
        let divisor: Int32 = 256
        
        // BT.709 weights mapped to BGRA byte positions -> [b, g, r, 0]
        var coeffs: [Int16] = [18, 183, 54, 0]
        
        let err = gray.withUnsafeMutableBytes { grayPtr -> vImage_Error in
            var dst = vImage_Buffer(data: grayPtr.baseAddress, height: vImagePixelCount(h),
                                    width: vImagePixelCount(w), rowBytes: w)
            return vImageMatrixMultiply_ARGB8888ToPlanar8(
                &src, &dst, &coeffs, divisor, nil, 0, vImage_Flags(kvImageNoFlags))
        }
        if err != kvImageNoError {
            throw FaceRecognitionError.imageConversionFailure
        }
        return gray
    }
}

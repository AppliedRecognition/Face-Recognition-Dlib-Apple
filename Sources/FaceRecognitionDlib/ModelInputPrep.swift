//
//  ModelInputPrep.swift
//
//
//  Created by Jakub Dolejs on 18/03/2025.
//

import Foundation
import UIKit
import CoreML
import Accelerate

extension UIImage {
    
    func toMLMultiArray() -> MLMultiArray? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        return cgImage.toMLMultiArray()
    }
}

extension CGImage {
    
    func toMLMultiArray() -> MLMultiArray? {
        let targetH = 150
        let targetW = 150
        let channels = 3
        let elementCount = targetH * targetW * channels
        
        var rgbaFormat = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: Unmanaged.passRetained(CGColorSpace(name: CGColorSpace.sRGB)!),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            version: 0,
            decode: nil,
            renderingIntent: .defaultIntent
        )
        defer { rgbaFormat.colorSpace.release() }
        
        var src = vImage_Buffer()
        defer { free(src.data) }
        guard vImageBuffer_InitWithCGImage(&src, &rgbaFormat, nil, self, vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
            return nil
        }
        
        var rgba150 = vImage_Buffer()
        defer { free(rgba150.data) }
        guard vImageBuffer_Init(&rgba150,
                                vImagePixelCount(targetH),
                                vImagePixelCount(targetW),
                                32,
                                vImage_Flags(kvImageNoFlags)) == kvImageNoError else {
            return nil
        }
        guard vImageScale_ARGB8888(&src, &rgba150, nil, vImage_Flags(kvImageHighQualityResampling)) == kvImageNoError else {
            return nil
        }
        
        var rgbData = [UInt8](repeating: 0, count: elementCount)
        rgbData.withUnsafeMutableBytes { rgbBytes in
            var rgbBuf = vImage_Buffer(data: rgbBytes.baseAddress!,
                                       height: vImagePixelCount(targetH),
                                       width: vImagePixelCount(targetW),
                                       rowBytes: targetW * channels)
            _ = vImageConvert_RGBA8888toRGB888(&rgba150, &rgbBuf, vImage_Flags(kvImageNoFlags))
        }
        
        var floats = [Float](repeating: 0, count: elementCount)
        floats.withUnsafeMutableBufferPointer { dst in
            rgbData.withUnsafeBufferPointer { src in
                vDSP_vfltu8(src.baseAddress!, 1, dst.baseAddress!, 1, vDSP_Length(elementCount))
            }
        }
        
        // Normalization
        var scale: Float = 255.0
        vDSP_vsdiv(floats, 1, &scale, &floats, 1, vDSP_Length(elementCount))
        
        let shape: [NSNumber] = [1, targetH, targetW, channels].map(NSNumber.init)
        guard let mlArray = try? MLMultiArray(shape: shape, dataType: .float32) else {
            return nil
        }
        
        if #available(iOS 15.4, *) {
            mlArray.withUnsafeMutableBytes { rawBuffer, _ in
                let dst = rawBuffer.bindMemory(to: Float.self)
                _ = floats.withUnsafeBufferPointer {
                    dst.baseAddress?.update(from: $0.baseAddress!, count: $0.count)
                }
            }
        } else {
            floats.withUnsafeBufferPointer { src in
                mlArray.dataPointer.withMemoryRebound(to: Float.self, capacity: src.count) { dst in
                    dst.update(from: src.baseAddress!, count: src.count)
                }
            }
        }
        
        return mlArray
    }
}

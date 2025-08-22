// The Swift Programming Language
// https://docs.swift.org/swift-book
import CoreML
import Accelerate
import VerIDCommonTypes
import DlibLandmarks
import UIKit

public class FaceRecognitionDlib: FaceRecognition {
    
    public typealias Version = V16
    public typealias TemplateData = [Float]
    
    private let model: DlibFaceRecognitionResnetV1
    private let faceAlignment: FaceAlignment
    
    public init() throws {
        guard let modelURL = Bundle.module.url(forResource: "DlibFaceRecognitionResnetV1", withExtension: "mlmodelc") else {
            throw FaceRecognitionError.modelFileNotFound("DlibFaceRecognitionResnetV1.mlmodelc")
        }
        self.model = try DlibFaceRecognitionResnetV1(contentsOf: modelURL)
        self.faceAlignment = try FaceAlignment()
    }
    
    public func createFaceRecognitionTemplates(from faces: [Face], in image: Image) async throws -> [FaceTemplateDlib] {
        let images = try self.faceAlignment.alignFaces(faces, inImage: image)
        return try images.map { image in
            guard let input = image.toMLMultiArray() else {
                throw FaceRecognitionError.imageConversionFailure
            }
            let output = try self.model.prediction(input: input)
            let count = output.Identity.count
            var array = [Float](repeating: 0, count: count)
            memcpy(&array, output.Identity.dataPointer, count * MemoryLayout<Float>.stride)
            return FaceTemplateDlib(data: array)
        }
    }
    
    public func compareFaceRecognitionTemplates(_ faceRecognitionTemplates: [FaceTemplateDlib], to template: FaceTemplateDlib) async throws -> [Float] {
        let n = vDSP_Length(template.data.count)
        var q2: Float = 0; vDSP_svesq(template.data, 1, &q2, n)
        
        return faceRecognitionTemplates.map { x in
            var dot: Float = 0
            vDSP_dotpr(template.data, 1, x.data, 1, &dot, n)
            var x2: Float = 0
            vDSP_svesq(x.data, 1, &x2, n)
            let d2 = max(0, q2 + x2 - 2*dot)
            return 1 - sqrt(d2)
        }
    }
}

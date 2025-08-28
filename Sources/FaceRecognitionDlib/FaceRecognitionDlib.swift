// The Swift Programming Language
// https://docs.swift.org/swift-book
import CoreML
import Accelerate
import VerIDCommonTypes
import DlibLandmarks
import UIKit

public class FaceRecognitionDlib: FaceRecognition {

    public var defaultThreshold: Float = 0.8
    
    public typealias Version = V16
    public typealias TemplateData = [Float]
    
    private let model: DlibFaceRecognitionResnetV1
    private let faceAlignment: FaceAlignment
    private static let meanVec: [Float] = [
        -0.1090,0.0742,0.0517,-0.0375,-0.0994,-0.0329,-0.0151,-0.1079,
         0.1378,-0.0923,0.2127,-0.0365,-0.2286,-0.0445,-0.0124,0.1445,
         
         -0.1405,-0.1195,-0.1007,-0.0680,0.0226,0.0363,0.0200,0.0452,
         -0.1115,-0.3154,-0.0861,-0.0857,0.0347,-0.0633,-0.0212,0.0540,
         
         -0.1759,-0.0452,0.0316,0.0744,-0.0404,-0.0740,0.1908,0.0074,
         -0.1750,0.0011,0.0608,0.2374,0.1846,0.0242,0.0188,-0.0836,
         
         0.1072,-0.2355,0.0457,0.1380,0.0863,0.0695,0.0580,-0.1418,
         0.0218,0.1214,-0.1886,0.0353,0.0607,-0.0795,-0.0504,-0.0594,
         
         0.2046,0.1072,-0.1132,-0.1250,0.1547,-0.1550,-0.0512,0.0616,
         -0.1190,-0.1681,-0.2682,0.0425,0.3917,0.1305,-0.1568,0.0228,
         
         -0.0711,-0.0270,0.0505,0.0680,-0.0632,-0.0314,-0.0845,0.0344,
         0.1964,-0.0246,-0.0093,0.2210,0.0085,0.0091,0.0245,0.0508,
         
         -0.0919,-0.0210,-0.1102,-0.0185,0.0413,-0.0808,0.0042,0.0965,
         -0.1852,0.1417,-0.0140,-0.0215,0.0028,-0.0162,-0.0834,-0.0259,
         
         0.1400,-0.2383,0.1883,0.1652,0.0180,0.1376,0.0564,0.0727,
         -0.0131,-0.0284,-0.1567,-0.0831,0.0615,-0.0196,0.0417,0.0311
    ]
    
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
            array = vDSP.subtract(FaceRecognitionDlib.meanVec, array)
            let norm = self.norm(array)
            if norm != 0 {
                vDSP.divide(array, norm, result: &array)
            }
            return FaceTemplateDlib(data: array)
        }
    }
    
    public func compareFaceRecognitionTemplates(_ faceRecognitionTemplates: [FaceTemplateDlib], to template: FaceTemplateDlib) async throws -> [Float] {
        let challengeNorm: Float = self.norm(template.data)
        let n = vDSP_Length(template.data.count)
        return faceRecognitionTemplates.map { t in
            var dotProduct: Float = 0.0
            vDSP_dotpr(template.data, 1, t.data, 1, &dotProduct, n)
            let templateNorm = self.norm(t.data)
            let cosine = dotProduct / (challengeNorm * templateNorm)
            let similarity = (cosine + 1.0) * 0.5
            return min(max(similarity, 0.0), 1.0)
        }
    }
    
    private func norm(_ template: [Float]) -> Float {
        let n = vDSP_Length(template.count)
        var norm: Float = 0.0
        vDSP_svesq(template, 1, &norm, n)
        return sqrt(norm)
    }
}

import XCTest
import VerIDCommonTypes
import FaceDetectionRetinaFace
import DlibLandmarks
@testable import FaceRecognitionDlib

final class FaceRecognitionDlibTests: XCTestCase {
    
    var recognition: FaceRecognitionDlib!
    
    override func setUpWithError() throws {
        self.recognition = try FaceRecognitionDlib()
    }
    
    func testAlignFace() async throws {
        let alignment = try FaceAlignment()
        let faceDetection = try FaceDetectionRetinaFace()
        guard let url = Bundle.module.url(forResource: "subject1-01", withExtension: "jpg") else {
            throw TestError()
        }
        let data = try Data(contentsOf: url)
        guard let cgImage = UIImage(data: data)?.cgImage else {
            throw TestError()
        }
        guard let veridImage = Image(cgImage: cgImage) else {
            throw TestError()
        }
        guard let face = try await faceDetection.detectFacesInImage(veridImage, limit: 1).first else {
            throw TestError()
        }
        let faceChip = try alignment.alignFaces([face], inImage: veridImage).first!
        XCTAssertEqual(faceChip.size.width, 150)
        XCTAssertEqual(faceChip.size.height, 150)
//        // Uncomment to attach image to test results
//        let att = XCTAttachment(image: faceChip)
//        att.lifetime = .keepAlways
//        self.add(att)
    }
    
    func testExtractTemplate() async throws {
        guard let url = Bundle.module.url(forResource: "subject1-01", withExtension: "jpg") else {
            throw TestError()
        }
        let data = try Data(contentsOf: url)
        guard let image = UIImage(data: data)?.cgImage else {
            throw TestError()
        }
        guard let veridImage = Image(cgImage: image) else {
            throw TestError()
        }
        let faceDetection = try FaceDetectionRetinaFace()
        guard let face = try await faceDetection.detectFacesInImage(veridImage, limit: 1).first else {
            throw TestError()
        }
        let templates = try await self.recognition.createFaceRecognitionTemplates(from: [face], in: veridImage)
        XCTAssertEqual(templates.count, 1)
    }
    
    func testCompareFaces() async throws {
        let threshold: Float = 0.5
        let subjectTemplates = try await self.subjectFaceTemplates()
        for (subject1, templates1) in subjectTemplates {
            for template1 in templates1 {
                for (subject2, templates2) in subjectTemplates {
                    let filteredTemplates = templates2.filter { $0 != template1 }
                    if filteredTemplates.isEmpty {
                        continue
                    }
                    let scores = try await self.recognition.compareFaceRecognitionTemplates(filteredTemplates, to: template1)
                    if scores.isEmpty {
                        continue
                    }
                    if subject1 == subject2 {
                        XCTAssertTrue(scores.allSatisfy { $0 >= threshold })
                    } else {
                        XCTAssertTrue(scores.allSatisfy { $0 < threshold })
                    }
                }
            }
        }
    }
    
    private func subjectFaceTemplates() async throws -> [String: [FaceTemplate<V16,[Float]>]] {
        let faceDetection = try FaceDetectionRetinaFace()
        let inputs = [("A","subject1-01"), ("A","subject1-02"), ("B","subject2-01")]
        
        var subjectTemplates: [(String, FaceTemplate<V16, [Float]>)] = []
        
        try await withThrowingTaskGroup(of: (String, FaceTemplate<V16, [Float]>).self) { group in
            for (name, imageName) in inputs {
                group.addTask {
                    guard let url = Bundle.module.url(forResource: imageName, withExtension: "jpg") else {
                        throw TestError()
                    }
                    let data = try Data(contentsOf: url)
                    guard let image = UIImage(data: data)?.cgImage else {
                        throw TestError()
                    }
                    guard let veridImage = Image(cgImage: image) else {
                        throw TestError()
                    }
                    guard let face = try await faceDetection.detectFacesInImage(veridImage, limit: 1).first else {
                        throw TestError()
                    }
                    guard let template = try await self.recognition
                        .createFaceRecognitionTemplates(from: [face], in: veridImage)
                        .first else {
                        throw TestError()
                    }
                    return (name, template)
                }
            }
            
            for try await result in group {
                subjectTemplates.append(result)
            }
        }
        
        return Dictionary(grouping: subjectTemplates, by: { $0.0 })
            .mapValues { $0.map { $0.1 } }
    }
}

fileprivate struct TestError: LocalizedError {
    
    init(_ errorDescription: String? = nil) {
        self.errorDescription = errorDescription
    }
    
    var errorDescription: String?
}

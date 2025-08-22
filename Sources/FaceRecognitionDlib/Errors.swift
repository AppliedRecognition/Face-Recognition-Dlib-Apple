//
//  Errors.swift
//
//
//  Created by Jakub Dolejs on 16/06/2025.
//

import Foundation

public enum FaceRecognitionError: LocalizedError {
    case imageConversionFailure
    case faceAlignmentFailure(Error)
    case modelFileNotFound(String)
    
    public var errorDescription: String? {
        switch self {
        case .imageConversionFailure:
            return NSLocalizedString("Image conversion failed", comment: "")
        case .faceAlignmentFailure:
            return NSLocalizedString("Face alignment failed", comment: "")
        case .modelFileNotFound(let name):
            return NSLocalizedString("Required model file \(name) not found", comment: "")
        }
    }
}

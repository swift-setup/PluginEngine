//
//  File.swift
//
//
//  Created by Qiwei Li on 1/22/23.
//

import Foundation

public enum FileUtilsErrors: LocalizedError {
    case fileNotFound
    case userCancelled
    case noSelectedDir

    public var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .userCancelled:
            return "User cancelled"
        case .noSelectedDir:
            return "No selected directory"
        }
    }
}

//
//  File.swift
//
//
//  Created by Qiwei Li on 1/22/23.
//

import Foundation

public enum RemotePluginLoadingErrors: LocalizedError {
    case downloadError
    case invalidRepoName
    case noDylibFound
    case invalidArch
    case invalidURL(url: String)
    case missingToken(key: String)
    
    public var errorDescription: String? {
        switch self {
            case .downloadError:
                return "Download error"
                
            case .invalidRepoName:
                return "Invalid repo name"
                
            case .noDylibFound:
                return "No dylib found"
                
            case .invalidURL(let url):
                return "Invalid remote url: \(url)"
                
            case .invalidArch:
                return "Unknown system arch"
            case .missingToken(let key):
                return "Missing token: \(key)"
        }
    }
}

public enum VersionError: LocalizedError {
    case invalidVersionFormat(String)
    
    public var errorDescription: String? {
        switch self {
            case .invalidVersionFormat(let format):
                return "Given format: \(format) is not a valid version format. Expect: x.y.z"
        }
    }
}

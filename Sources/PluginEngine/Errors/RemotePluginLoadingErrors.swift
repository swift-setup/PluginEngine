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
    
    public var errorDescription: String? {
        switch self {
            case .downloadError:
                return "Download error"
                
            case .invalidRepoName:
                return "Invalid repo name"
        }
    }
}

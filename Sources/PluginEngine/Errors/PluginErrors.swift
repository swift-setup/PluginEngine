//
//  File.swift
//  
//
//  Created by Qiwei Li on 1/22/23.
//

import Foundation

public enum PluginErrors: LocalizedError {
    case pluginNotFoundWithId(id: UUID)
    case pluginNotFoundWithName(name: String)

    public var errorDescription: String? {
        switch self {
            case .pluginNotFoundWithId(let id):
                return "Cannot found plugin with id: \(id)"
            case .pluginNotFoundWithName(let name):
                return "Cannot found plugin with name: \(name)"
        }
    }
}

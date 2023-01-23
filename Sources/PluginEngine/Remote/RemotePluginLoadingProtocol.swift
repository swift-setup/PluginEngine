//
//  File.swift
//  
//
//  Created by Qiwei Li on 1/22/23.
//

import Foundation

/**
 A protocol describes a procedure for loading plugin using remote url
 */
public protocol RemotePluginLoadingProtocol {
    /**
     Load plugin from url
     - parameter url: Remote url
     - returns Downloaded path
     */
    func load(from url: URL, version: Version) async throws -> PluginRepo
}

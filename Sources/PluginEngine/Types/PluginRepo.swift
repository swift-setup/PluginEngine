//
//  File.swift
//  
//
//  Created by Qiwei Li on 1/23/23.
//

import Foundation

public protocol PluginRepoProtocol {
    /**
     Local position for dylib
     */
    var localPosition: String { get set }
    /**
     Repo's readme
     */
    var readme: String { get set }
    /**
     Repo's version
     */
    var version: Version { get set }
}

public struct PluginRepo: PluginRepoProtocol, Codable {
    public var localPosition: String
    public var readme: String
    public var version: Version
    
    public init(localPosition: String, readme: String, version: Version) {
        self.localPosition = localPosition
        self.readme = readme
        self.version = version
    }
}

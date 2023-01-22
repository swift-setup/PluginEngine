//
//  File.swift
//
//
//  Created by Qiwei Li on 1/22/23.
//

import Foundation
import ZipArchive

public protocol NetworkRequestProtocol {
    func getRequest(for request: URLRequest) async throws -> (Data, URLResponse)
}

public protocol ZipProtocol {
    func unzipFileAtPath(_ path: String, toDestination: String)
    func contentsOfDirectory(atPath path: String) throws -> [String]
}

public struct NetworkClient: NetworkRequestProtocol {
    public init() {}
    
    public func getRequest(for request: URLRequest) async throws -> (Data, URLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        return (data, response)
    }
}

public struct ZipClient: ZipProtocol {
    public init() {}
    
    public func unzipFileAtPath(_ path: String, toDestination: String) {
        SSZipArchive.unzipFile(atPath: path, toDestination: toDestination)
    }
    
    public func contentsOfDirectory(atPath path: String) throws -> [String] {
        let fm = FileManager.default
        return try fm.contentsOfDirectory(atPath: path)
    }
}

public struct GitHubRemotePluginClient: RemotePluginLoadingProtocol {
    let networkClient: NetworkRequestProtocol
    let zipClient: ZipProtocol
    
    public init(networkClient: NetworkRequestProtocol = NetworkClient(), zipClient: ZipProtocol = ZipClient()) {
        self.networkClient = networkClient
        self.zipClient = zipClient
    }
    
    
    public func load(from remote: URL, version: Version) async throws -> PluginRepo {
        let targetFileName = "macos_\(try getArch().rawValue).zip"
        let releasePath = "releases/download/\(version.toString())/\(targetFileName)"
        
        let downloadURL = remote.appendingPathComponent(releasePath)
        let downloadPath = FileManager.default.temporaryDirectory.appendingPathComponent(targetFileName).path
        
        try await downloadPackage(from: downloadURL, to: downloadPath)
        let readme = try await getReadme(from: remote, version: version)
        
        // unzip to document directory
        let repoName = getRepoName(from: remote.absoluteString)!
        let destination = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(repoName).path
        let dylibFile = try unzip(downloadPath, toDestination: destination)
        
        return PluginRepo(localPosition: dylibFile, readme: readme ?? "No content", version: version)
    }
    
    internal func getArch() throws -> SystemArch {
        #if arch(arm64)
        return SystemArch.ARM64
        #else
        return SystemArch.X86_64
        #endif
    }
    
    /**
     * Download the package from the given url to the given path and return the first file with .dylib extension
     */
    internal func unzip(_ path: String, toDestination: String) throws -> String {
        zipClient.unzipFileAtPath(path, toDestination: toDestination)
        let items = try zipClient.contentsOfDirectory(atPath: toDestination)
        for item in items {
            if item.hasSuffix(".dylib") {
                return URL(fileURLWithPath: toDestination).appendingPathComponent(item).path
            }
        }
        throw RemotePluginLoadingErrors.noDylibFound
    }
    
    /**
     * Get the repo name from the given url
     */
    internal func getRepoName(from url: String) -> String? {
        let regex = try! NSRegularExpression(pattern: "(?:https?://)?(?:www\\.)?github\\.com/(\\S+)", options: [])
        let range = NSRange(location: 0, length: url.utf16.count)
        let match = regex.firstMatch(in: url, options: [], range: range)
        if let match = match {
            let repoName = (url as NSString).substring(with: match.range(at: 1))
            return repoName.replacingOccurrences(of: ".git", with: "")
        }
        return nil
    }
    
    /**
     Download package from GitHub Release
     */
    internal func downloadPackage(from url: URL, to: String) async throws {
        let request = URLRequest(url: url)
        let (data, response) = try await networkClient.getRequest(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw RemotePluginLoadingErrors.downloadError }
        
        let fileURL = URL(fileURLWithPath: to)
        try data.write(to: fileURL)
    }
    
    /**
     Get the contents of the readme.
     Will try [readme, README, readme.md, README.md]
     */
    internal func getReadme(from url: URL, version: Version) async throws -> String? {
        // only keep the part without .com
        // for example: https://github.com/sirily11/TestPlugin.git or https://github.com/sirily11/TestPlugin
        // will be converted to sirily11/TestPlugin
        
        guard let repoName = getRepoName(from: url.absoluteString) else {
            throw RemotePluginLoadingErrors.invalidRepoName
        }
        
        // try README.md, README, readme.md, readme
        let readmeNames = ["README.md", "README", "readme.md", "readme"]
        let baseURL = URL(string: "https://raw.githubusercontent.com")
        
        // construct the url for each readme name with the version and the repo name
        
        let readmeURLs = readmeNames.map { name in
            baseURL!.appendingPathComponent(repoName).appendingPathComponent(version.toString()).appendingPathComponent(name)
        }
        
        // try to get the readme from the url
        for url in readmeURLs {
            let request = URLRequest(url: url)
            let (data, response) = try await networkClient.getRequest(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { continue }
            
            return String(data: data, encoding: .utf8)!
        }
        
        return nil
    }
}

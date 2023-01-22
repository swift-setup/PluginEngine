//
//  File.swift
//
//
//  Created by Qiwei Li on 1/22/23.
//

import Foundation

public protocol NetworkRequestProtocol {
    func getRequest(for request: URLRequest) async throws -> (Data, URLResponse)
}


public struct NetworkClient: NetworkRequestProtocol {
    public init() {
        
    }
    
    public func getRequest(for request: URLRequest) async throws -> (Data, URLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        return (data, response)
    }
}



public struct GitHubRemotePluginClient: RemotePluginLoadingProtocol {
    public let networkClient: NetworkRequestProtocol
    
    public init(networkClient: NetworkRequestProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }
    
    
    public func load(from remote: URL, version: Version) async throws -> PluginRepo {
        let targetFileName = "macos_arm64.zip"
        let releasePath = "releases/download/\(version.toString())/\(targetFileName)"

        let downloadURL = remote.appendingPathComponent(releasePath)
        let downloadPath = FileManager.default.temporaryDirectory.appendingPathComponent(targetFileName).path
        
        try await downloadPackage(from: downloadURL, to: downloadPath)
        let readme = try await getReadme(from: remote, version: version)

        return PluginRepo(localPosition: "./file.dylib", readme: readme ?? "No readme", version: .init(1, 1, 1))
    }

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

    internal func downloadPackage(from url: URL, to: String) async throws {
        let request = URLRequest(url: url)
        let (data, response) = try await networkClient.getRequest(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw RemotePluginLoadingErrors.downloadError }

        let fileURL = URL(fileURLWithPath: to)
        try data.write(to: fileURL)
    }

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

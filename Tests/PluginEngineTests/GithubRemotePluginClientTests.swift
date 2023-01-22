//
//  GithubRemotePluginClientTests.swift
//  
//
//  Created by Qiwei Li on 1/22/23.
//

import XCTest
@testable import PluginEngine

class TestNetworkClient: NetworkRequestProtocol {
    var calledRequest: URLRequest?
    
    func getRequest(for request: URLRequest) async throws -> (Data, URLResponse) {
        calledRequest = request
        return ("Hello world".data(using: .utf8)!, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

class TestNetworkClientWithCount: NetworkRequestProtocol {
    var count = 0
    
    func getRequest(for request: URLRequest) async throws -> (Data, URLResponse) {
        count += 1
        if count < 3 {
            return (Data(), HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!)
        }
        
        return ("Hello world".data(using: .utf8)!, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

final class GithubRemotePluginClientTests: XCTestCase {
    func testGetRepoName() throws {
        let client = GitHubRemotePluginClient()
        let repo = client.getRepoName(from: "https://github.com/swift-setup/PluginEngine")
        XCTAssertEqual(repo, "swift-setup/PluginEngine")
    }

    func testGetRepoNameWithGit() throws {
        let client = GitHubRemotePluginClient()
        let repo = client.getRepoName(from: "https://github.com/swift-setup/PluginEngine.git")
        XCTAssertEqual(repo, "swift-setup/PluginEngine")
    }

    func testGetRepoNameWithoutRepoName() throws {
        let client = GitHubRemotePluginClient()
        let repo = client.getRepoName(from: "https://github.com")
        XCTAssertNil(repo)
    }
    
    func testGetReadme() async throws {
        let client = TestNetworkClient()
        let githubClient = GitHubRemotePluginClient(networkClient: client)
        let readme = try await githubClient.getReadme(from: URL(string: "https://github.com/swift-setup/PluginEngine.git")!, version: .init(1, 0, 0))
        XCTAssertEqual(readme, "Hello world")
        let callURL = client.calledRequest!.url!.absoluteString
        XCTAssertTrue(callURL.contains("swift-setup/PluginEngine/1.0.0/README.md"))
    }
    
    func testGetReadme2() async throws {
        let client = TestNetworkClientWithCount()
        let githubClient = GitHubRemotePluginClient(networkClient: client)
        let readme = try await githubClient.getReadme(from: URL(string: "https://github.com/swift-setup/PluginEngine.git")!, version: .init(1, 0, 0))
        XCTAssertEqual(readme, "Hello world")
        XCTAssertEqual(client.count, 3)
    }
}

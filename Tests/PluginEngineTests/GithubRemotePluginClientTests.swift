//
//  GithubRemotePluginClientTests.swift
//
//
//  Created by Qiwei Li on 1/22/23.
//

@testable import PluginEngine
import PluginInterface
import XCTest

class TestNetworkClient: NetworkRequestProtocol {
    var calledRequest: URLRequest?

    func getRequest(for request: URLRequest) async throws -> (Data, URLResponse) {
        calledRequest = request
        return ("Hello world".data(using: .utf8)!, HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

class TestFirstNetworkClient: NetworkRequestProtocol {
    var calledRequest: URLRequest?

    func getRequest(for request: URLRequest) async throws -> (Data, URLResponse) {
        if calledRequest == nil {
            calledRequest = request
        }
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

class TestVersionNetworkClient: NetworkRequestProtocol {
    var calledRequest: URLRequest?

    func getRequest(for request: URLRequest) async throws -> (Data, URLResponse) {
        calledRequest = request
        let versions: [GetGithubReleaseDto] = [
            GetGithubReleaseDto(tagName: "v1.0.0"),
            GetGithubReleaseDto(tagName: "v1.0.1"),
        ]
        
        return (try! JSONEncoder().encode(versions), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
}

class TestZipClient: ZipProtocol {
    func unzipFileAtPath(_: String, toDestination _: String) {}

    func contentsOfDirectory(atPath _: String) throws -> [String] {
        ["a.readme", "b.dylib"]
    }
}

class TestZipClientError: ZipProtocol {
    func unzipFileAtPath(_: String, toDestination _: String) {}

    func contentsOfDirectory(atPath _: String) throws -> [String] {
        ["a.readme"]
    }
}

class MockStore: StoreUtilsProtocol {
    func set(_ value: Any?, forKey defaultName: String, from plugin: (any PluginInterfaceProtocol)?) {
        
    }
    
    func removeObject(forKey defaultName: String, from plugin: (any PluginInterfaceProtocol)?) {
        
    }
    
    func get<T>(forKey defaultName: String, from plugin: (any PluginInterfaceProtocol)?) -> T? {
        return "TOKEN" as? T
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
    
    func testGetArch() throws {
        let client = GitHubRemotePluginClient()
        let arch = try client.getArch()
        XCTAssertNotNil(arch)
    }

    func testGetReadme() async throws {
        let client = TestNetworkClient()
        let githubClient = GitHubRemotePluginClient(networkClient: client)
        let readme = try await githubClient.getReadme(from: URL(string: "https://github.com/swift-setup/PluginEngine.git")!, version: .init(1, 0, 0))
        XCTAssertEqual(readme, "Hello world")
        let callURL = client.calledRequest!.url!.absoluteString
        XCTAssertTrue(callURL.contains("swift-setup/PluginEngine/1.0.0/README.md"))
    }
    
    func testGetReadmeWithStringVersion() async throws {
        let client = TestNetworkClient()
        let githubClient = GitHubRemotePluginClient(networkClient: client)
        let readme = try await githubClient.getReadme(from: URL(string: "https://github.com/swift-setup/PluginEngine.git")!, version: "1.1.2")
        XCTAssertEqual(readme, "Hello world")
        let callURL = client.calledRequest!.url!.absoluteString
        XCTAssertTrue(callURL.contains("swift-setup/PluginEngine/1.1.2/README.md"))
    }

    func testGetReadme2() async throws {
        let client = TestNetworkClientWithCount()
        let githubClient = GitHubRemotePluginClient(networkClient: client)
        let readme = try await githubClient.getReadme(from: URL(string: "https://github.com/swift-setup/PluginEngine.git")!, version: .init(1, 0, 0))
        XCTAssertEqual(readme, "Hello world")
        XCTAssertEqual(client.count, 3)
    }

    func testUnzip() async throws {
        let zipClient = TestZipClient()
        let githubClient = GitHubRemotePluginClient(zipClient: zipClient)
        let dylib = try githubClient.unzip("/usr/bin", toDestination: "/usr/lib")
        XCTAssertEqual(dylib, "/usr/lib/b.dylib")
    }

    func testUnzipWithError() async throws {
        let zipClient = TestZipClientError()
        let githubClient = GitHubRemotePluginClient(zipClient: zipClient)
        XCTAssertThrowsError(try githubClient.unzip("/usr/bin", toDestination: "/usr/lib"))
    }
    
    func testLoad() async throws {
        let client = TestFirstNetworkClient()
        let zipClient = TestZipClient()
        let githubClient = GitHubRemotePluginClient(networkClient: client, zipClient: zipClient)
        let repo = try await githubClient.load(from: URL(string: "https://github.com/swift-setup/plugin.git")!, version: .init(1, 1, 1))
        let request = client.calledRequest!
        let url = request.url!.absoluteString
        
        XCTAssertTrue(url.lowercased() == url)
        XCTAssertEqual(repo.readme, "Hello world")
        let localPosition = repo.localPosition
        XCTAssertTrue(localPosition.contains("1.1.1/b.dylib"))
    }
    
    func testLoadWithStringVersion() async throws {
        let client = TestNetworkClient()
        let zipClient = TestZipClient()
        let githubClient = GitHubRemotePluginClient(networkClient: client, zipClient: zipClient)
        let repo = try await githubClient.load(from: URL(string: "https://github.com/swift-setup/PluginEngine.git")!, version: "1.1.1")
        XCTAssertEqual(repo.readme, "Hello world")
        let localPosition = repo.localPosition
        XCTAssertTrue(localPosition.contains("b.dylib"))
    }
    
    func testFetchVersions() async throws {
        let client = TestVersionNetworkClient()
        let store = MockStore()
        let githubClient = GitHubRemotePluginClient(networkClient: client, store: store)
        let versions = try await githubClient.versions(from: URL(string: "https://github.com/swift-setup/PluginEngine.git")!)
        XCTAssertEqual(versions.count, 2)
        XCTAssertEqual(client.calledRequest!.url!.absoluteString, "https://api.github.com/repos/swift-setup/PluginEngine/releases")
    }
}

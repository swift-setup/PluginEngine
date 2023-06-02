//
//  VersionTests.swift
//
//
//  Created by Qiwei Li on 1/22/23.
//

@testable import PluginEngine
import XCTest

final class VersionTests: XCTestCase {
    func testVersion() throws {
        let version: Version = "1.0.0"
        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minor, 0)
        XCTAssertEqual(version.patch, 0)
    }

    func testVersion2() throws {
        let version: Version = "v1.0.0"
        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minor, 0)
        XCTAssertEqual(version.patch, 0)

        XCTAssertEqual(version.toString(), "v1.0.0")
    }

    func testInvalidVersion() {
        let version: Version = "1"
        XCTAssertEqual(version.major, -1)
        XCTAssertEqual(version.minor, -1)
        XCTAssertEqual(version.patch, -1)
    }
}

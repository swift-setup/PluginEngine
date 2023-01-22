//
//  VersionTests.swift
//  
//
//  Created by Qiwei Li on 1/22/23.
//

import XCTest
@testable import PluginEngine

final class VersionTests: XCTestCase {
    func testVersion() throws {
        let version: Version = "1.0.0"
        XCTAssertEqual(version.major, 1)
        XCTAssertEqual(version.minor, 0)
        XCTAssertEqual(version.patch, 0)
    }
}

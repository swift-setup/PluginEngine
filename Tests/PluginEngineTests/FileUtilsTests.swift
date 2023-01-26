//
//  FileUtilsTests.swift
//  
//
//  Created by Qiwei Li on 1/25/23.
//

import XCTest
@testable import PluginEngine

class MockFileManager: FileManager {
    var writtenURL: URL? = nil
    
    override func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        self.writtenURL = url
    }
    
    override func contentsOfDirectory(atPath path: String) throws -> [String] {
        return ["a", "b"]
    }
    
}

final class FileUtilsTests: XCTestCase {

    func testCreateDirs() throws {
        let fm = MockFileManager()
        let utils = FileUtils(fm: fm)
        try utils.createDirs(at: URL(filePath: "/usr/files/"))
        XCTAssertEqual(fm.writtenURL?.absoluteFilePath, "/usr/files/")
        
        try utils.createDirs(at: URL(filePath: "/usr/files2/"))
        XCTAssertEqual(fm.writtenURL?.absoluteFilePath, "/usr/files2/")
    }
    
    func testList() throws {
        let fm = MockFileManager()
        let utils = FileUtils(fm: fm)
        utils.currentWorkSpace = URL(filePath: "/a/b")
        
        let items = try utils.list(includes: ["a", "b"])
        XCTAssertEqual(items.count, 6)
        XCTAssertTrue(items[2].contains("/a/a"))
        XCTAssertTrue(items[3].contains("/a/b"))
        XCTAssertTrue(items[4].contains("/b/a"))
        XCTAssertTrue(items[5].contains("/b/b"))
    }
    
    func testListRootOnly() throws {
        let fm = MockFileManager()
        let utils = FileUtils(fm: fm)
        utils.currentWorkSpace = URL(filePath: "/a/b")
        
        let items = try utils.list(includes: [])
        XCTAssertEqual(items.count, 2)
    }
}

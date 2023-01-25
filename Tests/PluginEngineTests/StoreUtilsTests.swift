//
//  StoreUtilsTests.swift
//  
//
//  Created by Qiwei Li on 1/25/23.
//

import XCTest
@testable import PluginEngine
import PluginInterface

struct SimpleTestPlugin: PluginInterfaceProtocol {
    var id: UUID = UUID()
    
    var manifest: ProjectManifest = ProjectManifest(displayName: "Test", bundleIdentifier: "com.test", author: "tester", shortDescription: "Testing", repository: "https://google.com", keywords: [])
}

final class StoreUtilsTests: XCTestCase {
    var utils: UserDefaultStore!
    var plugin: SimpleTestPlugin!
    
    override func setUp() async throws {
        utils = UserDefaultStore()
        plugin = SimpleTestPlugin()
    }
    
    override func tearDown() {
        utils.removeObject(forKey: "Hello", from: nil)
    }
    
    func testStoreUtils() throws {
        utils.set("Hello", forKey: "Hello", from: nil)
        let value: String = utils.get(forKey: "Hello", from: nil)!
        XCTAssertEqual(value, "Hello")
    }
    
    func testStoreUtilsWithPlugin() throws {
        // if store using plugin, then the value will be store on pluginbased
        // other plugin cannot get the value
        utils.set("Hello", forKey: "Hello", from: plugin)
        let value: String = utils.get(forKey: "Hello", from: plugin)!
        let valueWithoutPlugin: String? = utils.get(forKey: "Hello", from: nil)
        XCTAssertEqual(value, "Hello")
        XCTAssertNil(valueWithoutPlugin)
    }
}

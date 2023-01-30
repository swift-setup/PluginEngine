import XCTest
import SwiftUI
@testable import PluginEngine
@testable import PluginInterface

struct TestPlugin: PluginInterfaceProtocol {
    var manifest: ProjectManifest = ProjectManifest(displayName: "test", bundleIdentifier: "test1", author: "test", shortDescription: "", repository: "", keywords: [])
    
    var id: UUID = UUID()
}

struct TestPlugin2: PluginInterfaceProtocol {
    var manifest: ProjectManifest = ProjectManifest(displayName: "test", bundleIdentifier: "test2", author: "test", shortDescription: "", repository: "", keywords: [])
    
    var id: UUID = UUID()
    
    var body: some View {
        Text("Hello world")
    }
}

struct TestPlugin3: PluginInterfaceProtocol {
    var manifest: ProjectManifest = ProjectManifest(displayName: "test", bundleIdentifier: "test1", author: "test", shortDescription: "", repository: "", keywords: [])
    
    var id: UUID = UUID()
    
    var body: some View {
        Text("Hello world")
    }
}


class TestNSPanel: NSPanelUtilsProtocol {
    var confirmCounter = 0
    var alertCounter = 0
    var defaultConfirmResult: Bool
    
    init(defaultConfirmResult: Bool) {
        self.defaultConfirmResult = defaultConfirmResult
    }
    
    func confirm(title: String, subtitle: String, confirmButtonText: String?, cancelButtonText: String?, alertStyle: NSAlert.Style?) -> Bool {
        confirmCounter += 1
        return defaultConfirmResult
    }
    
    func alert(title: String, subtitle: String, okButtonText: String?, alertStyle: NSAlert.Style?) {
        alertCounter += 1
    }
}

class TestPluginUtils: PluginUtilsProtocol {
    func load(at path: String, fileUtils: PluginInterface.FileUtilsProtocol, panelUtils: PluginInterface.NSPanelUtilsProtocol, storeUtils: StoreUtilsProtocol) -> any PluginInterfaceProtocol {
        var plugin = TestPlugin()
        plugin.manifest.bundleIdentifier = path
        return plugin
    }
}

final class PluginEngineTests: XCTestCase {
    func testLoadWithConfirm() async throws {
        let panel = TestNSPanel(defaultConfirmResult: true)
        let pluginUtils = TestPluginUtils()
        let engine = PluginEngine(pluginUtils: pluginUtils)
        engine.setup(nsPanelUtils: panel)
        
        _ = engine.load(path: "abc")
        
        XCTAssertEqual(panel.confirmCounter, 1)
        XCTAssertEqual(panel.alertCounter, 0)
        
        _ = engine.load(path: "abc2")
        
        XCTAssertEqual(panel.confirmCounter, 2)
        XCTAssertEqual(panel.alertCounter, 0)
        
        panel.defaultConfirmResult = false
        _ = engine.load(path: "abc3")
        
        XCTAssertEqual(panel.confirmCounter, 3)
        XCTAssertEqual(panel.alertCounter, 1)
        XCTAssertEqual(engine.plugins.count, 2)
        XCTAssertFalse(engine.isLoadingRemote)
    }
    
    
    func testRender() async throws {
        let panel = TestNSPanel(defaultConfirmResult: true)
        let engine = PluginEngine()
        engine.setup(nsPanelUtils: panel)
        let plugin = TestPlugin()
        let plugin2 = TestPlugin2()
        
        engine.addPlugin(plugin: plugin)
        engine.addPlugin(plugin: plugin2)
        
        try engine.use(plugin: plugin.manifest.bundleIdentifier)
        XCTAssertEqual(plugin.id, engine.currentPlugin?.id)
        _ = await engine.render()
        
        try engine.use(id: plugin2.id)
        XCTAssertEqual(plugin2.id, engine.currentPlugin?.id)
        _ = await engine.render()
        
        XCTAssertEqual(panel.confirmCounter, 0)
        XCTAssertFalse(engine.isLoadingRemote)
    }
    
    func testRemove() throws {
        let engine = PluginEngine()
        let plugin = TestPlugin()
        let plugin2 = TestPlugin2()
        
        engine.addPlugin(plugin: plugin)
        engine.addPlugin(plugin: plugin2)
        
        XCTAssertEqual(engine.plugins.count, 2)
        
        engine.removePlugin(plugin: plugin)
        XCTAssertEqual(engine.plugins.count, 1)
        
        try engine.use(plugin: plugin2.manifest.bundleIdentifier)
        XCTAssertEqual(engine.currentPlugin?.manifest.bundleIdentifier, plugin2.manifest.bundleIdentifier)
        engine.removePlugin(plugin: plugin2)
        XCTAssertNil(engine.currentPlugin)
        
    }
    
    func testAddPlugin() throws {
        let engine = PluginEngine()
        let plugin = TestPlugin()
        let plugin2 = TestPlugin2()
        let plugin3 = TestPlugin3()
        
        engine.addPlugin(plugin: plugin)
        engine.addPlugin(plugin: plugin2)
        engine.addPlugin(plugin: plugin3)
        
        XCTAssertEqual(engine.plugins.count, 2)
    }
}

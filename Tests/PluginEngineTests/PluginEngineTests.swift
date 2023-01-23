import XCTest
import SwiftUI
@testable import PluginEngine
@testable import PluginInterface

struct TestPlugin: PluginInterfaceProtocol {
    var manifest: ProjectManifest = ProjectManifest(displayName: "test", bundleIdentifier: "test", author: "test", shortDescription: "", repository: "", keywords: [])
    
    var id: UUID = UUID()
}

struct TestPlugin2: PluginInterfaceProtocol {
    var manifest: ProjectManifest = ProjectManifest(displayName: "test", bundleIdentifier: "test", author: "test", shortDescription: "", repository: "", keywords: [])
    
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
    func load(at path: String, fileUtils: PluginInterface.FileUtilsProtocol, panelUtils: PluginInterface.NSPanelUtilsProtocol) -> any PluginInterfaceProtocol {
        TestPlugin()
    }
}

final class PluginEngineTests: XCTestCase {
    func testLoadWithConfirm() async throws {
        let panel = TestNSPanel(defaultConfirmResult: true)
        let pluginUtils = TestPluginUtils()
        let engine = PluginEngine(pluginUtils: pluginUtils, nsPanelUtils: panel)
        
        engine.load(path: "abc")
        
        XCTAssertEqual(panel.confirmCounter, 1)
        XCTAssertEqual(panel.alertCounter, 0)
        
        engine.load(path: "abc")
        
        XCTAssertEqual(panel.confirmCounter, 2)
        XCTAssertEqual(panel.alertCounter, 0)
        
        panel.defaultConfirmResult = false
        engine.load(path: "abc")
        
        XCTAssertEqual(panel.confirmCounter, 3)
        XCTAssertEqual(panel.alertCounter, 1)
        XCTAssertEqual(engine.plugins.count, 2)
    }
    
    
    func testRender() async throws {
        let panel = TestNSPanel(defaultConfirmResult: true)
        let engine = PluginEngine(nsPanelUtils: panel)
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
    }
}

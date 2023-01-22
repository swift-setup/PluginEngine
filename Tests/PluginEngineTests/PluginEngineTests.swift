import XCTest
import SwiftUI
@testable import PluginEngine
@testable import PluginInterface

struct TestPlugin: PluginInterfaceProtocol {
    var pluginName: String = "test-plugin"
    
    var id: UUID = UUID()
}

struct TestPlugin2: PluginInterfaceProtocol {
    var pluginName: String = "test-plugin"
    
    var id: UUID = UUID()
    
    var body: some View {
        Text("Hello world")
    }
}

final class PluginEngineTests: XCTestCase {
    func testRender() async throws {
        let engine = PluginEngine()
        let plugin = TestPlugin()
        let plugin2 = TestPlugin2()
        
        engine.addPlugin(plugin: plugin)
        engine.addPlugin(plugin: plugin2)
        
        try engine.use(plugin: plugin.pluginName)
        XCTAssertEqual(plugin.id, engine.currentPlugin?.id)
        _ = await engine.render()
        
        try engine.use(id: plugin2.id)
        XCTAssertEqual(plugin2.id, engine.currentPlugin?.id)
        _ = await engine.render()
    }
}

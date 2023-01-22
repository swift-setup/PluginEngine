import PluginInterface
import Foundation
import SwiftUI

public class PluginEngine: ObservableObject {
    @Published public private(set) var currentPlugin: (any PluginInterfaceProtocol)?
    @Published public private(set) var plugins: [any PluginInterfaceProtocol] = []
    private let fileUtils: FileUtilsProtocol
    private let pluginUtils: PluginUtilsProtocol
    
    /**
     Initialize a plugin engine
     - parameter fileUtils: File utils helper for plguins to interact with the file system
     */
    public init(fileUtils: FileUtilsProtocol = FileUtils(), pluginUtils: PluginUtilsProtocol = PluginUtils()) {
        self.fileUtils = fileUtils
        self.pluginUtils = pluginUtils
    }
    
    /**
     Load plugin at [path]
     - parameter path: Plugin path
     */
    public func load(path: String) {
        let plugin = self.pluginUtils.load(at: path, fileUtils: self.fileUtils)
        plugins.append(plugin)
    }
    
    public func use(id: UUID) throws {
        let plugin = plugins.first { p in
            p.id == id
        }
        guard let plugin = plugin else {
            throw PluginErrors.pluginNotFoundWithId(id: id)
        }
        use(plugin: plugin)
    }
    
    
    public func use(plugin name: String) throws {
        let plugin = plugins.first { p in
            p.pluginName == name
        }
        guard let plugin = plugin else {
            throw PluginErrors.pluginNotFoundWithName(name: name)
        }
        use(plugin: plugin)
    }
    
    public func use(plugin: any PluginInterfaceProtocol) {
        plugin.setup()
        plugin.onUse()
        currentPlugin = plugin
    }
    
    func handle() {
        //TODO: Add handling method which will handle the event using plugins
    }
    
    @MainActor
    public func render() -> AnyView {
        guard let currentPlugin = currentPlugin else {
            //TODO: use handle method to handle the error
            return AnyView(EmptyView())
        }
        
        if let plugin = currentPlugin as? (any PluginUIInterfaceProtocol) {
            return AnyView(plugin.view)
        }
        
        return AnyView(Text("Plugin doesn't have a renderer"))
    }
}

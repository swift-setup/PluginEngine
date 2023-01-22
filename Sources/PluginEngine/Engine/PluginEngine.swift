import PluginInterface
import Foundation
import SwiftUI


public extension PluginInterfaceProtocol {
    var id: UUID { UUID() }
}

public class PluginEngine {
    public private(set) var currentPlugin: PluginInterfaceProtocol?
    public private(set) var plugins: [PluginInterfaceProtocol] = []
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
    
    public func use(plugin: PluginInterfaceProtocol) {
        plugin.setup()
        plugin.onUse()
        currentPlugin = plugin
    }
    
    func handle() {
        //TODO: Add handling method which will handle the event using plugins
    }
    
    @MainActor
    public func render() -> any View {
        guard let currentPlugin = currentPlugin else {
            //TODO: use handle method to handle the error
            return EmptyView()
        }
        
        if let plugin = currentPlugin as? (any PluginUIInterfaceProtocol) {
            return plugin.view
        }
        
        return Text("Plugin doesn't have a renderer")
    }
}

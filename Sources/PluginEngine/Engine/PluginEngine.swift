import PluginInterface
import Foundation
import SwiftUI

public class PluginEngine: ObservableObject {
    @Published public private(set) var currentPlugin: (any PluginInterfaceProtocol)?
    @Published public private(set) var plugins: [any PluginInterfaceProtocol] = []
    @Published public private(set) var remotePluginLoader: (any RemotePluginLoadingProtocol)
    
    @Published public private(set) var isLoadingRemote = false
    
    private let fileUtils: FileUtilsProtocol
    private let pluginUtils: PluginUtilsProtocol
    
    /**
     Initialize a plugin engine
     - parameter fileUtils: File utils helper for plguins to interact with the file system
     */
    public init(fileUtils: FileUtilsProtocol = FileUtils(), pluginUtils: PluginUtilsProtocol = PluginUtils(), remotePluginLoader: RemotePluginLoadingProtocol = GitHubRemotePluginClient()) {
        self.fileUtils = fileUtils
        self.pluginUtils = pluginUtils
        self.remotePluginLoader = remotePluginLoader
    }
    
    /**
     Load plugin at [path]
     - parameter path: Plugin path
     */
    public func load(path: String) {
        let plugin = self.pluginUtils.load(at: path, fileUtils: self.fileUtils)
        plugins.append(plugin)
    }
    
    public func load(url: String, version: Version) async throws -> PluginRepo {
        isLoadingRemote = true
        do {
            guard let url = URL(string: url) else {
                throw RemotePluginLoadingErrors.invalidURL(url: url)
            }
            let repo = try await remotePluginLoader.load(from: url, version: version)
            load(path: repo.localPosition)
            return repo
        } catch {
            isLoadingRemote = false
            throw error
        }
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
        
        if currentPlugin.view is EmptyView {
            return AnyView(Text("Plugin doesn't have a renderer"))
        }
        
        let view = currentPlugin.view as (any View)
        
        return AnyView(view)
    }
}

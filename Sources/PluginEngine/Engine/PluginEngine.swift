import PluginInterface
import Foundation
import SwiftUI

public class PluginEngine: ObservableObject {
    @Published public private(set) var currentPlugin: (any PluginInterfaceProtocol)?
    @Published public private(set) var plugins: [any PluginInterfaceProtocol] = []
    @Published public private(set) var remotePluginLoader: (any RemotePluginLoadingProtocol)
    
    @Published public private(set) var isLoadingRemote = false
    
    private var fileUtils: FileUtilsProtocol!
    private var nsPanelUtils: NSPanelUtilsProtocol!
    private var storeUtils: StoreUtilsProtocol!
    private let pluginUtils: PluginUtilsProtocol
    
    
    /**
     Initialize a plugin engine
     - parameter fileUtils: File utils helper for plguins to interact with the file system
     */
    public init(pluginUtils: PluginUtilsProtocol = PluginUtils(), remotePluginLoader: RemotePluginLoadingProtocol = GitHubRemotePluginClient()) {
        self.pluginUtils = pluginUtils
        self.remotePluginLoader = remotePluginLoader
    }
    
    public func setup(fileUtils: FileUtilsProtocol = FileUtils(), nsPanelUtils: NSPanelUtilsProtocol = NSPanelUtils(), storeUtils: StoreUtilsProtocol = UserDefaultStore()) {
        self.fileUtils = fileUtils
        self.nsPanelUtils = nsPanelUtils
        self.storeUtils = storeUtils
    }
    
    func handle() {
        //TODO: Add handling method which will handle the event using plugins
    }
}


//MARK: load plugin
public extension PluginEngine {
    func addPlugin(plugin: any PluginInterfaceProtocol) {
        plugins.append(plugin)
    }
    
    func addPluginBuilder(builder: PluginBuilder) {
        let plugin = builder.build(fileUtils: self.fileUtils, nsPanelUtils: self.nsPanelUtils, storeUtils: storeUtils)
        addPlugin(plugin: plugin)
    }
    
    /**
     This function is removing a plugin from the list of available plugins. It first checks if the plugin being removed is the current plugin and sets it to nil if it is. It then removes all instances of the plugin from the list of available plugins by matching the plugin's bundle identifier.
     - parameter plugin: The plugin you want to remove
     */
    func removePlugin(plugin: any PluginInterfaceProtocol) {
        if currentPlugin?.manifest.bundleIdentifier == plugin.manifest.bundleIdentifier {
            currentPlugin = nil
        }
        plugins.removeAll { p in
            p.manifest.bundleIdentifier == plugin.manifest.bundleIdentifier
        }
    }
    
    /**
     Loads a plugin located at the specified path.
     - parameter path: The file path of the plugin to be loaded.
     - parameter autoConfirm: A boolean value indicating whether or not to automatically confirm the plugin's installation. Default is false.
     */
    func load(path: String, autoConfirm: Bool = false, autoAdd: Bool = true) -> (any PluginInterfaceProtocol)? {
        if !autoConfirm {
            let confirmed = nsPanelUtils.confirm(title: "You are going to load plugin", subtitle: path, confirmButtonText: "confirm", cancelButtonText: "cancel", alertStyle: .critical)
            if !confirmed {
                nsPanelUtils.alert(title: "Cancelled", subtitle: "Cancelled loading the plugin", okButtonText: "OK", alertStyle: .informational)
                return nil
            }
        }
        let plugin = self.pluginUtils.load(at: path, fileUtils: self.fileUtils, panelUtils: self.nsPanelUtils, storeUtils: storeUtils)
        
        if autoAdd {
            addPlugin(plugin: plugin)
        }
        return plugin
    }
    
    /**
     Asynchronously loads a plugin from a specified URL and version.
     - parameter url: The URL from where the plugin should be loaded.
     - parameter version: The version of the plugin to be loaded.
     - throws: An error if there is a problem loading the plugin.
     - returns: A PluginRepo object containing the loaded plugin.
     */
    @MainActor
    func load(url: String, version: Version) async throws -> (PluginRepo, (any PluginInterfaceProtocol)?) {
        isLoadingRemote = true
        do {
            guard let url = URL(string: url) else {
                throw RemotePluginLoadingErrors.invalidURL(url: url)
            }
            let repo = try await remotePluginLoader.load(from: url, version: version)
            let plugin = load(path: repo.localPosition, autoAdd: false)
            isLoadingRemote = false
            return (repo, plugin)
        } catch {
            isLoadingRemote = false
            throw error
        }
    }
}

//MARK: use plugin
public extension PluginEngine {
    func use(id: UUID) throws {
        let plugin = plugins.first { p in
            p.id == id
        }
        guard let plugin = plugin else {
            throw PluginErrors.pluginNotFoundWithId(id: id)
        }
        use(plugin: plugin)
    }
    
    /**
     Use bundle identifier
     */
    func use(plugin name: String) throws {
        let plugin = plugins.first { p in
            p.manifest.bundleIdentifier == name
        }
        guard let plugin = plugin else {
            throw PluginErrors.pluginNotFoundWithName(name: name)
        }
        use(plugin: plugin)
    }
    
    func use(plugin: any PluginInterfaceProtocol) {
        plugin.setup()
        plugin.onUse()
        currentPlugin = plugin
    }
}

//MARK: render

public extension PluginEngine {
    @MainActor
    func render() -> AnyView {
        guard let currentPlugin = currentPlugin else {
            //TODO: use handle method to handle the error
            return AnyView(EmptyView())
        }
        
        if currentPlugin.view is EmptyView {
            if !(currentPlugin.settings is EmptyView) {
                return AnyView(
                    VStack {
                        Text("This plugin offers a preference page")
                        Button("Open preference") {
                            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                        }
                    })
            }
            
            return AnyView(Text("Plugin doesn't have a renderer"))
        }
        
        let view = currentPlugin.view as (any View)
        
        return AnyView(view)
    }
    
    @MainActor
    @ViewBuilder
    func renderSettings() -> some View {
        TabView {
            ForEach(plugins, id: \.manifest.bundleIdentifier) { plugin in
                if !(plugin.settings is EmptyView){
                    let view = plugin.settings as (any View)
                    AnyView(view)
                        .padding()
                        .tabItem {
                            Label(plugin.manifest.displayName, systemImage: plugin.manifest.systemImageName ?? "info.circle.fill")
                        }
                }
            }
        }
    }
}

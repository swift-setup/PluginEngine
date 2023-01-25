//
//  File.swift
//  
//
//  Created by Qiwei Li on 1/25/23.
//

import Foundation
import PluginInterface

public class UserDefaultStore: ObservableObject, StoreUtilsProtocol {
    internal let store = UserDefaults.standard
    
    public init() {}
    
    internal func getKeyName(plugin: (any PluginInterfaceProtocol)?, forKey key: String) -> String {
        if let plugin = plugin {
            return "\(plugin.manifest.bundleIdentifier).\(key)"
        }
        return key
    }
    
    public func set(_ value: Any?, forKey defaultName: String, from plugin: (any PluginInterfaceProtocol)?) {
        store.set(value, forKey: getKeyName(plugin: plugin, forKey: defaultName))
    }
    
    public func removeObject(forKey defaultName: String, from plugin: (any PluginInterfaceProtocol)?) {
        store.removeObject(forKey: getKeyName(plugin: plugin, forKey: defaultName))
    }
    
    public func get<T>(forKey defaultName: String, from plugin: (any PluginInterfaceProtocol)?) -> T? {
        let value = store.object(forKey: getKeyName(plugin: plugin, forKey: defaultName))
        if let value = value as? T {
            return value
        }
        return nil
    }
}

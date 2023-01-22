//
//  File.swift
//  
//
//  Created by Qiwei Li on 1/22/23.
//

import Foundation
import PluginInterface

fileprivate typealias InitFunction = @convention(c) () -> UnsafeMutableRawPointer

public protocol PluginUtilsProtocol {
    func load(at path: String, fileUtils: FileUtilsProtocol) -> any PluginInterfaceProtocol
}

public struct PluginUtils: PluginUtilsProtocol {
    public init() {}
    
    public func load(at path: String, fileUtils: FileUtilsProtocol) -> any PluginInterfaceProtocol {
        let openRes = dlopen(path, RTLD_NOW|RTLD_LOCAL)
        if openRes != nil {
            defer {
                dlclose(openRes)
            }

            let symbolName = "createPlugin"
            let sym = dlsym(openRes, symbolName)

            if sym != nil {
                let f: InitFunction = unsafeBitCast(sym, to: InitFunction.self)
                let pluginPointer = f()
                let builder = Unmanaged<PluginBuilder>.fromOpaque(pluginPointer).takeRetainedValue()
                return builder.build(fileUtils: fileUtils) as! (any PluginUIInterfaceProtocol)
            }
            else {
                fatalError("error loading lib: symbol \(symbolName) not found, path: \(path)")
            }
        }
        else {
            if let err = dlerror() {
                fatalError("error opening lib: \(String(format: "%s", err)), path: \(path)")
            }
            else {
                fatalError("error opening lib: unknown error, path: \(path)")
            }
        }
    }
}

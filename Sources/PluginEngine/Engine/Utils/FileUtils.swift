//
//  File.swift
//
//
//  Created by Qiwei Li on 1/22/23.
//

import AppKit
import Foundation
import PluginInterface

public class FileUtils: FileUtilsProtocol {
    public private(set) var currentWorkSpace: URL?
    
    public var currentWorkSpacePath: String? {
        get {
            currentWorkSpace?.absoluteFilePath
        }
    }
    
    public init() {}
    
    public func openFile(at path: String) throws -> Data {
        guard let currentDir = currentWorkSpace else {
            throw FileUtilsErrors.noSelectedDir
        }
        let fileURL = currentDir.appending(component: path)
        if !fileURL.isFileURL {
            throw FileUtilsErrors.invalidFileURL(url: fileURL)
        }
        
        return try Data(contentsOf: fileURL)
    }
    
    public func writeFile(at path: String, with content: String) throws {
        guard let currentDir = currentWorkSpace else {
            throw FileUtilsErrors.noSelectedDir
        }
        
        let fileURL = currentDir.appending(component: path)
        if !fileURL.isFileURL {
            throw FileUtilsErrors.invalidFileURL(url: fileURL)
        }
        try self.writeFile(at: fileURL, with: content)
    }
    
    public func delete(at path: String) throws {
        guard let currentDir = currentWorkSpace else {
            throw FileUtilsErrors.noSelectedDir
        }
        
        let fileURL = currentDir.appending(component: path)
        if !fileURL.isFileURL {
            throw FileUtilsErrors.invalidFileURL(url: fileURL)
        }
        try self.delete(at: fileURL)
    }

    public func updateCurrentWorkSpace() throws -> URL {
        let dialog = NSOpenPanel()
        dialog.title = "Choose a folder"
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true

        if dialog.runModal() == .OK {
            if let result = dialog.url {
                currentWorkSpace = result
                return result
            }
        }

        throw FileUtilsErrors.userCancelled
    }

    public func list() throws -> [String] {
        guard let currentWorkSpace = currentWorkSpace else {
            throw FileUtilsErrors.noSelectedDir
        }

        let fm = FileManager.default
        guard let path = currentWorkSpace.absoluteFilePath else {
            throw FileUtilsErrors.invalidFileURL(url: currentWorkSpace)
        }
        let items = try fm.contentsOfDirectory(atPath: path)
        return items
    }

    public func openFile(at path: URL) throws -> Data {
        if !path.isFileURL {
            throw FileUtilsErrors.invalidFileURL(url: path)
        }
        return try Data(contentsOf: path)
    }

    public func writeFile(at path: URL, with content: String) throws {
        if !path.isFileURL {
            throw FileUtilsErrors.invalidFileURL(url: path)
        }
        try content.write(to: path, atomically: true, encoding: .utf8)
    }

    public func createDirs(at path: URL) throws {
        if !path.isFileURL {
            throw FileUtilsErrors.invalidFileURL(url: path)
        }
        let fm = FileManager.default
        try fm.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
    }

    public func delete(at path: URL) throws {
        if !path.isFileURL {
            throw FileUtilsErrors.invalidFileURL(url: path)
        }
        let fm = FileManager.default
        try fm.removeItem(at: path)
    }
}

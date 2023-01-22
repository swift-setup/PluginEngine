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
    private(set) var currentDir: URL?
    
    public init() {}

    public func updateCurrentWorkSpace() throws -> URL {
        let dialog = NSOpenPanel()
        dialog.title = "Choose a folder"
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true

        if dialog.runModal() == .OK {
            if let result = dialog.url {
                currentDir = result
                return result
            }
        }

        throw FileUtilsErrors.userCancelled
    }

    public func list() throws -> [String] {
        guard let currentDir = currentDir else {
            throw FileUtilsErrors.noSelectedDir
        }

        let fm = FileManager.default
        let path = currentDir.absoluteString.replacingOccurrences(of: "file://", with: "")
        let items = try fm.contentsOfDirectory(atPath: path)
        return items
    }

    public func openFile(at path: URL) throws -> Data {
        return try Data(contentsOf: path)
    }

    public func writeFile(at path: URL, with content: String) throws {
        try content.write(to: path, atomically: true, encoding: .utf8)
    }

    public func createDirs(at path: URL) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
    }

    public func delete(at path: URL) throws {
        let fm = FileManager.default
        try fm.removeItem(at: path)
    }
}

//
//  File.swift
//
//
//  Created by Qiwei Li on 1/22/23.
//

import AppKit
import Foundation
import PluginInterface
import UniformTypeIdentifiers

public class FileUtils: ObservableObject, FileUtilsProtocol {
    @Published public internal(set) var currentWorkSpace: URL?

    public var currentWorkSpacePath: String? {
        currentWorkSpace?.absoluteFilePath
    }

    private let fm: FileManager

    public init(fm: FileManager = FileManager.default) {
        self.fm = fm
    }

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

        try writeFile(at: fileURL, with: content)
    }

    public func delete(at path: String) throws {
        guard let currentDir = currentWorkSpace else {
            throw FileUtilsErrors.noSelectedDir
        }

        let fileURL = currentDir.appending(component: path)
        if !fileURL.isFileURL {
            throw FileUtilsErrors.invalidFileURL(url: fileURL)
        }
        try delete(at: fileURL)
    }

    @MainActor
    public func updateCurrentWorkSpace() throws -> URL {
        let dialog = NSOpenPanel()
        dialog.title = "Choose a folder"
        dialog.canChooseFiles = false
        dialog.canChooseDirectories = true
        dialog.canCreateDirectories = true

        if dialog.runModal() == .OK {
            if let result = dialog.url {
                currentWorkSpace = result
                return result
            }
        }

        throw FileUtilsErrors.userCancelled
    }

    public func list(includes: [String]) throws -> [String] {
        guard let currentWorkSpace = currentWorkSpace else {
            throw FileUtilsErrors.noSelectedDir
        }

        guard let path = currentWorkSpace.absoluteFilePath else {
            throw FileUtilsErrors.invalidFileURL(url: currentWorkSpace)
        }

        var items: [String] = []
        var paths: [String] = [path]
        paths.append(contentsOf: includes)

        for path in paths {
            if path.contains(currentWorkSpacePath!) {
                let filesIndir = try fm.contentsOfDirectory(atPath: path)
                items.append(contentsOf: filesIndir)
            } else {
                let newPath = currentWorkSpace.appending(path: path)
                guard let filePath = newPath.absoluteFilePath else {
                    throw FileUtilsErrors.invalidFileURL(url: newPath)
                }
                let filesIndir = (try? fm.contentsOfDirectory(atPath: filePath)) ?? []
                items.append(contentsOf: filesIndir.map {
                    var url = URL(filePath: path)
                    url = url.appending(path: $0)
                    return url.absoluteString.replacingOccurrences(of: "file:///", with: "")
                })
            }
        }
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
        try fm.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
        fm.createFile(atPath: path.absoluteFilePath!, contents: content.data(using: .utf8))
    }

    public func createDirs(at path: URL) throws {
        if !path.isFileURL {
            throw FileUtilsErrors.invalidFileURL(url: path)
        }
        try fm.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
    }

    public func delete(at path: URL) throws {
        if !path.isFileURL {
            throw FileUtilsErrors.invalidFileURL(url: path)
        }
        try fm.removeItem(at: path)
    }

    public func showOpenFilePanel(allowedFileTypes: [UTType]) throws -> URL {
        let dialog = NSOpenPanel()
        dialog.title = "Choose a file"
        dialog.canChooseFiles = true
        dialog.canChooseDirectories = false
        dialog.canCreateDirectories = false
        dialog.allowsMultipleSelection = false
        dialog.allowedContentTypes = allowedFileTypes

        if dialog.runModal() == .OK {
            if let result = dialog.url {
                return result
            }
        }

        throw FileUtilsErrors.userCancelled
    }

    public func showSaveFilePanel(allowedFileTypes: [UTType], defaultFileName: String) throws -> URL {
        let dialog = NSSavePanel()
        dialog.title = "Choose a file"
        dialog.canCreateDirectories = true
        dialog.allowedContentTypes = allowedFileTypes
        dialog.nameFieldStringValue = defaultFileName

        if dialog.runModal() == .OK {
            if let result = dialog.url {
                return result
            }
        }

        throw FileUtilsErrors.userCancelled
    }

    public func writeFile(at path: URL, with content: Data) throws {
        if !path.isFileURL {
            throw FileUtilsErrors.invalidFileURL(url: path)
        }
        try fm.createDirectory(at: path.deletingLastPathComponent(), withIntermediateDirectories: true)
        fm.createFile(atPath: path.absoluteFilePath!, contents: content)
    }

    public func writeFile(at path: String, with content: Data) throws {
        guard let currentDir = currentWorkSpace else {
            throw FileUtilsErrors.noSelectedDir
        }
        let fileURL = currentDir.appending(component: path)
        if !fileURL.isFileURL {
            throw FileUtilsErrors.invalidFileURL(url: fileURL)
        }
        try writeFile(at: fileURL, with: content)
    }
}

//
//  File.swift
//  
//
//  Created by Qiwei Li on 1/25/23.
//

import Foundation

public extension URL {
    /**
     Returns the file path as a string. If the path is not a valid file URL, the property returns nil.
     */
    var absoluteFilePath: String? {
        get {
            if self.isFileURL {
                return absoluteString.replacingOccurrences(of: "file://", with: "")
            }
            return nil
        }
    }
}

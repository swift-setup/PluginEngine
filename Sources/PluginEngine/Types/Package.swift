//
//  File.swift
//
//
//  Created by Qiwei Li on 1/22/23.
//

import Foundation

public struct Version {
    /// The major version according to the semantic versioning standard.
    public let major: Int

    /// The minor version according to the semantic versioning standard.
    public let minor: Int

    /// The patch version according to the semantic versioning standard.
    public let patch: Int

    /// The pre-release identifier according to the semantic versioning standard, such as `-beta.1`.
    public let prereleaseIdentifiers: [String]

    /// The build metadata of this version according to the semantic versioning standard, such as a commit hash.
    public let buildMetadataIdentifiers: [String]
    
    public let startsWithV: Bool

    /// Initializes a version struct with the provided components of a semantic version.
    ///
    /// - Parameters:
    ///   - major: The major version number.
    ///   - minor: The minor version number.
    ///   - patch: The patch version number.
    ///   - prereleaseIdentifiers: The pre-release identifier.
    ///   - buildMetaDataIdentifiers: Build metadata that identifies a build.
    ///
    /// - Precondition: `major >= 0 && minor >= 0 && patch >= 0`.
    /// - Precondition: `prereleaseIdentifiers` can contain only ASCII alpha-numeric characters and "-".
    /// - Precondition: `buildMetaDataIdentifiers` can contain only ASCII alpha-numeric characters and "-".
    public init(_ major: Int, _ minor: Int, _ patch: Int, prereleaseIdentifiers _: [String] = [], buildMetadataIdentifiers _: [String] = [], startsWithV: Bool = false) {
        precondition(major >= 0 && minor >= 0 && patch >= 0, "Version components must be non-negative")
        self.major = major
        self.minor = minor
        self.patch = patch
        prereleaseIdentifiers = []
        buildMetadataIdentifiers = []
        self.startsWithV = startsWithV
    }
}

extension Version: Comparable {
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`, `a ==
    /// b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    ///
    /// - Returns: A boolean value indicating the result of the equality test.
    @inlinable public static func == (lhs: Version, rhs: Version) -> Bool {
        return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
    }

    /// Returns a Boolean value indicating whether the value of the first
    /// argument is less than that of the second argument.
    ///
    /// The precedence is determined according to rules described in the [Semantic Versioning 2.0.0](https://semver.org) standard, paragraph 11.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        if lhs.patch != rhs.patch {
            return lhs.patch < rhs.patch
        }
        return false
    }
}

extension Version: Codable {
    public func toString() -> String {
        var string = "\(major).\(minor).\(patch)"
        if !prereleaseIdentifiers.isEmpty {
            string += "-" + prereleaseIdentifiers.joined(separator: ".")
        }
        if !buildMetadataIdentifiers.isEmpty {
            string += "+" + buildMetadataIdentifiers.joined(separator: ".")
        }
        
        if startsWithV {
            string = "v" + string
        }
        return string
    }
}

extension Version: ExpressibleByStringLiteral {
    /// Initializes a version struct with the provided string literal.
    ///
    /// - Parameter version: A string literal to use for creating a new version struct.
    public init(stringLiteral value: String) {
        // parse the version string
        let components = value.split(separator: ".")
        guard components.count >= 3 else {
            fatalError("Invalid version string: \(value)")
        }
        var firstComponent: String = String(components[0])
        var startsWithV = false
        if firstComponent.lowercased().contains("v") {
            startsWithV = true
            firstComponent = firstComponent.lowercased().replacingOccurrences(of: "v", with: "")
        }
        
        let major = Int(firstComponent)!
        let minor = Int(components[1])!
        let patch = Int(components[2])!
        self.init(major, minor, patch, startsWithV: startsWithV)
    }
}

// Copyright (c) 1868 Charles Babbage
// Modernized by Robert "r0ml" Lefkowitz <code@liberally.net> in 2024

import Foundation

// Extend FileManager to check if a path is a symbolic link
extension FileManager {
    func isSymbolicLink(atPath path: String) -> Bool {
        do {
            let attributes = try attributesOfItem(atPath: path)
            return attributes[.type] as? FileAttributeType == .typeSymbolicLink
        } catch {
            return false
        }
    }
}



//
//  File.swift
//  KSPlayer
//
//  Created by Maniganda Saravanan on 28/06/2025.
//

import Foundation

public extension Bundle {
    static var ksPlayer: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        // Fallback for non-SPM use (e.g., source files added manually)
        return Bundle(for: KSVideoPlayer.self)
        #endif
    }
}

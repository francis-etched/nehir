// SPDX-FileCopyrightText: 2026 Aleksei Gurianov and Nehir contributors
// SPDX-License-Identifier: GPL-2.0-only

import Foundation
@testable import Nehir
import Testing

@MainActor
struct TabbedRailOrientationTests {
    @Test func railOrderMatchesSplitOrderAndClickMappingInBothOrientations() {
        for count in [1, 2, 3, 5] {
            let column = NiriContainer()
            for index in 0 ..< count {
                column.appendChild(NiriWindow(token: WindowToken(pid: 12345, windowId: index + 1)))
            }
            for orientation in [Monitor.Orientation.horizontal, .vertical] {
                for storageIndex in 0 ..< count {
                    let expectedVisual = orientation == .vertical ? storageIndex : count - 1 - storageIndex
                    #expect(column
                        .visualTileIndex(forStorageTileIndex: storageIndex, orientation: orientation) == expectedVisual)
                    #expect(column
                        .storageTileIndex(forVisualTileIndex: expectedVisual, orientation: orientation) == storageIndex)
                }
                #expect(column.visualTileIndex(forStorageTileIndex: -1, orientation: orientation) == nil)
                #expect(column.storageTileIndex(forVisualTileIndex: count, orientation: orientation) == nil)
            }
        }
    }
}

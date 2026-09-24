// SPDX-FileCopyrightText: 2026 Aleksei Gurianov and Nehir contributors
// SPDX-License-Identifier: GPL-2.0-only

import Foundation
@testable import Nehir
import Testing

struct CrossAxisFrameWriteTests {
    @Test func landscapePortraitTransferShrinksBeforeMovingAndGrowing() {
        let landscape = CGRect(x: 0, y: 0, width: 2560, height: 1410)
        let portrait = CGRect(x: -1440, y: 1440, width: 1440, height: 2536)
        #expect(AXWindowService.frameWriteOrder(currentFrame: landscape, targetFrame: portrait)
            == .shrinkThenPositionThenSize)
        #expect(AXWindowService.frameWriteOrder(currentFrame: portrait, targetFrame: landscape)
            == .shrinkThenPositionThenSize)
    }

    @Test func uniformGrowthAndShrinkKeepExistingOrder() {
        let small = CGRect(x: 8, y: 8, width: 600, height: 400)
        let large = CGRect(x: 0, y: 0, width: 1200, height: 800)
        #expect(AXWindowService.frameWriteOrder(currentFrame: small, targetFrame: large) == .positionThenSize)
        #expect(AXWindowService.frameWriteOrder(currentFrame: large, targetFrame: small) == .sizeThenPosition)
    }
}

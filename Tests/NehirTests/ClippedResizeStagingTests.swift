// SPDX-FileCopyrightText: 2026 Aleksei Gurianov and Nehir contributors
// SPDX-License-Identifier: GPL-2.0-only

import Foundation
@testable import Nehir
import Testing

struct ClippedResizeStagingTests {
    @Test func stagesClippedFootprintBeforeShrinkingOnEitherAxis() {
        for screen in [
            CGRect(x: -1440, y: 1440, width: 1440, height: 2560),
            CGRect(x: 0, y: 0, width: 2560, height: 1440)
        ] {
            for size in [CGSize(width: 1428, height: 1250), CGSize(width: 800, height: 600)] {
                let current = CGRect(
                    x: screen.maxX - size.width / 2,
                    y: screen.minY,
                    width: size.width,
                    height: size.height
                )
                let target = CGRect(
                    x: screen.maxX - size.width / 2,
                    y: screen.minY,
                    width: size.width / 2,
                    height: size.height / 2
                )
                let staged = AXWindowService.resizeStagingFrame(
                    currentFrame: current,
                    targetFrame: target,
                    visibleFrame: screen
                )
                #expect(staged != nil)
                #expect(screen.contains(staged!))
                #expect(staged!.size == current.size)
            }
        }
    }

    @Test func doesNotStageFittingOrUnplaceableWindows() {
        let screen = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let current = CGRect(x: 0, y: 0, width: 800, height: 600)
        let target = CGRect(x: 0, y: 0, width: 400, height: 600)
        #expect(AXWindowService
            .resizeStagingFrame(currentFrame: current, targetFrame: target, visibleFrame: screen) == nil)
        #expect(AXWindowService.resizeStagingFrame(
            currentFrame: CGRect(x: -100, y: 0, width: 1200, height: 600),
            targetFrame: target,
            visibleFrame: screen
        ) == nil)
        #expect(AXWindowService.resizeStagingFrame(
            currentFrame: current.offsetBy(dx: 500, dy: 0),
            targetFrame: target.offsetBy(dx: 0, dy: -100),
            visibleFrame: screen
        ) == nil)
    }
}

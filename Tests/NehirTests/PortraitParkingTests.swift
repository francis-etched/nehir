// SPDX-FileCopyrightText: 2026 Aleksei Gurianov and Nehir contributors
// SPDX-License-Identifier: GPL-2.0-only

import Foundation
@testable import Nehir
import Testing

struct PortraitParkingTests {
    @Test func portraitParkingKeepsTitleBarOnDisplayAndAvoidsOtherMonitors() {
        let portrait = HiddenPlacementMonitorContext(
            id: Monitor.ID(displayId: 2),
            frame: CGRect(x: -1440, y: 1440, width: 1440, height: 2560),
            visibleFrame: CGRect(x: -1440, y: 1440, width: 1440, height: 2560)
        )
        let neighbor = HiddenPlacementMonitorContext(
            id: Monitor.ID(displayId: 4),
            frame: CGRect(x: 0, y: 0, width: 2560, height: 1440),
            visibleFrame: CGRect(x: 0, y: 0, width: 2560, height: 1410)
        )
        for edge in [AxisHideEdge.minimum, .maximum] {
            for height in [CGFloat(600), 1250, 2500] {
                let size = CGSize(width: 1440, height: height)
                let result = HiddenWindowPlacementResolver.placement(
                    for: size,
                    requestedEdge: edge,
                    orthogonalOrigin: -1440,
                    baseReveal: 1,
                    scale: 2,
                    orientation: .vertical,
                    monitor: portrait,
                    monitors: [portrait, neighbor]
                ).frame(for: size)
                #expect(result.maxY <= portrait.visibleFrame.maxY)
                #expect(result.minY >= portrait.visibleFrame.minY)
                #expect(result.intersection(portrait.frame).width <= 1)
                #expect(result.intersection(neighbor.frame).isEmpty)
            }
        }
    }
    @Test func inactiveWorkspaceParkingRejectsClampedLanes() {
        let main = HiddenPlacementMonitorContext(id: Monitor.ID(displayId: 4), frame: CGRect(x: 0, y: 0, width: 2560, height: 1440), visibleFrame: CGRect(x: 0, y: 0, width: 2560, height: 1410))
        let laptop = HiddenPlacementMonitorContext(id: Monitor.ID(displayId: 1), frame: CGRect(x: 2560, y: -982, width: 1512, height: 982), visibleFrame: CGRect(x: 2560, y: -982, width: 1512, height: 950))
        let portrait = HiddenPlacementMonitorContext(id: Monitor.ID(displayId: 2), frame: CGRect(x: -1440, y: 1440, width: 1440, height: 2560), visibleFrame: CGRect(x: -1440, y: 1440, width: 1440, height: 2560))
        for height in [CGFloat(950), 1410] {
            for sourceY in [CGFloat(-982), 0, 62, 522, 2750] {
                let size = CGSize(width: 1262, height: height)
                let point = HiddenWindowPlacementResolver.physicalScreenEdgeOrigin(for: size, requestedSide: .left, targetY: sourceY, baseReveal: 1, scale: 2, monitor: main, monitors: [main, laptop, portrait])
                let frame = CGRect(origin: point, size: size)
                #expect(frame.maxY <= main.visibleFrame.maxY)
                #expect(frame.minY >= main.visibleFrame.minY)
                #expect(frame.intersection(laptop.frame).isEmpty)
                #expect(frame.intersection(portrait.frame).isEmpty)
                #expect(frame.intersection(main.frame).width == 1)
            }
        }
    }

}

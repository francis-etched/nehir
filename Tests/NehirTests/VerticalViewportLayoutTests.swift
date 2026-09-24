// SPDX-FileCopyrightText: 2026 Aleksei Gurianov and Nehir contributors
// SPDX-License-Identifier: GPL-2.0-only

import Foundation
@testable import Nehir
import Testing

@MainActor
struct VerticalViewportLayoutTests {
    @Test(arguments: [2, 3, 5])
    func navigationRevealsRowsInTopToBottomOrder(count: Int) throws {
        let engine = NiriLayoutEngine()
        let workspace = UUID()
        let root = NiriRoot(workspaceId: workspace)
        engine.roots[workspace] = root
        let frame = CGRect(x: -1440, y: 1440, width: 1440, height: 2536)
        var state = ViewportState()
        state.orientation = .vertical
        var windows: [NiriWindow] = []
        for index in 0 ..< count {
            let row = NiriContainer()
            row.height = .proportion(0.5)
            // Deliberately different physical width: scrolling must use row heights.
            row.cachedWidth = 1440
            let window = NiriWindow(token: WindowToken(pid: 12345, windowId: index + 1))
            row.appendChild(window)
            root.appendChild(row)
            engine.tokenToNode[window.token] = window
            windows.append(window)
        }
        for index in Array(windows.indices) + Array(windows.indices.reversed()) {
            engine.ensureSelectionVisible(
                node: windows[index], in: workspace, motion: .disabled,
                state: &state, workingFrame: frame, gaps: 12,
                orientation: .vertical, revealTrigger: .explicitNavigation
            )
            let frames = engine.calculateLayout(
                state: state, workspaceId: workspace, monitorFrame: frame,
                gaps: (horizontal: 12, vertical: 12), orientation: .vertical
            )
            let selected = try #require(frames[windows[index].token])
            #expect(selected.width == frame.width)
            #expect(selected.height == 1250)
            #expect(selected.minY >= frame.minY - 0.5)
            #expect(selected.maxY <= frame.maxY + 0.5)
            #expect(state.activeColumnIndex == index)
            if index > 0, let previous = frames[windows[index - 1].token],
               previous.intersects(frame)
            {
                #expect(previous.minY >= selected.maxY)
            }
        }
    }

    @Test func maximizedFittingUsesTopInsetRatherThanBottomInset() {
        let state = ViewportState()
        let working = CGRect(x: -1440, y: 1450, width: 1440, height: 2500)
        let parent = CGRect(x: -1440, y: 1440, width: 1440, height: 2560)
        let areas = state.normalizedFittingAreas(
            viewportSpan: working.height, workingArea: working,
            viewFrame: parent, orientation: .vertical
        )
        #expect(areas.origin(of: areas.working) == 0)
        #expect(areas.origin(of: areas.parent) == -50)
        let offset = state.computeModeAwareCenteredOffset(
            currentViewStart: 0, targetPos: 0, targetSpan: 1000,
            mode: .maximized, areas: areas, gap: 12
        )
        #expect(offset == -730)
    }

    @Test func loneRowScrollMovesAlongVerticalAxis() {
        let rect = CGRect(x: -1440, y: 1440, width: 1440, height: 2536)
        let geometry = SingleWindowViewportGeometry(
            rect: rect, centerOffset: 0, orientation: .vertical
        )
        let rendered = geometry.renderedRect(viewOffset: 240, scale: 2)
        #expect(rendered == rect.offsetBy(dx: 0, dy: 240))
    }

    @Test func loneWindowRecomputesSizeWhenOrientationChanges() {
        let engine = NiriLayoutEngine()
        let row = NiriContainer()
        let window = NiriWindow(token: WindowToken(pid: 12345, windowId: 99))
        row.appendChild(window)
        let landscape = CGRect(x: 0, y: 0, width: 2560, height: 1410)
        let portrait = CGRect(x: -1440, y: 1440, width: 1440, height: 2536)
        let context = NiriLayoutEngine.SingleWindowLayoutContext(
            container: row, window: window, maxWidthFraction: 1
        )
        let first = engine.singleWindowViewportGeometry(
            for: context, in: landscape, scale: 2, gaps: 12, orientation: .horizontal
        )
        #expect(first.rect == landscape)
        row.loneWindowLayoutWidthOverride = first.rect.width
        let second = engine.singleWindowViewportGeometry(
            for: context, in: portrait, scale: 2, gaps: 12, orientation: .vertical
        )
        #expect(second.rect == portrait)
        #expect(second.centerOffset == 0)
    }

    @Test func centeredLoneRowUsesPortraitHeight() {
        let engine = NiriLayoutEngine()
        let row = NiriContainer()
        let window = NiriWindow(token: WindowToken(pid: 12345, windowId: 100))
        row.appendChild(window)
        let portrait = CGRect(x: -1440, y: 1440, width: 1440, height: 2536)
        let context = NiriLayoutEngine.SingleWindowLayoutContext(
            container: row, window: window, maxWidthFraction: 0.5, orientation: .vertical
        )
        let geometry = engine.singleWindowViewportGeometry(
            for: context, in: portrait, scale: 2, gaps: 12
        )
        let rendered = geometry.renderedRect(viewOffset: geometry.centerOffset, scale: 2)
        #expect(rendered.height == portrait.height / 2)
        #expect(rendered.width == portrait.width)
        #expect(rendered.midY == portrait.midY)
    }

    @Test func splitRowsKeepWindowsSideBySideWhileRevealingEachRow() throws {
        for rowCount in [1, 2, 3, 5] {
            for windowsPerRow in [2, 3] {
                let engine = NiriLayoutEngine()
                let workspace = UUID()
                let root = NiriRoot(workspaceId: workspace)
                engine.roots[workspace] = root
                let working = CGRect(x: -1440, y: 1440, width: 1440, height: 2536)
                var state = ViewportState()
                state.orientation = .vertical
                var rows: [[NiriWindow]] = []
                for rowIndex in 0 ..< rowCount {
                    let row = NiriContainer()
                    row.height = .proportion(0.5)
                    root.appendChild(row)
                    var windows: [NiriWindow] = []
                    for columnIndex in 0 ..< windowsPerRow {
                        let token = WindowToken(pid: 12345, windowId: rowIndex * windowsPerRow + columnIndex + 1)
                        let window = NiriWindow(token: token)
                        row.appendChild(window)
                        engine.tokenToNode[token] = window
                        windows.append(window)
                    }
                    rows.append(windows)
                }
                for row in rows {
                    // Reveal using the rightmost window, not just the first split.
                    let selected = try #require(row.last)
                    engine.ensureSelectionVisible(
                        node: selected, in: workspace, motion: .disabled,
                        state: &state, workingFrame: working, gaps: 12,
                        orientation: .vertical, revealTrigger: .explicitNavigation
                    )
                    let layout = engine.calculateLayout(
                        state: state, workspaceId: workspace, monitorFrame: working,
                        gaps: (horizontal: 12, vertical: 12), orientation: .vertical
                    )
                    let frames = try row.map { try #require(layout[$0.token]) }
                    let first = try #require(frames.first)
                    let last = try #require(frames.last)
                    #expect(first.minX == working.minX)
                    #expect(last.maxX == working.maxX)
                    #expect(first.minY >= working.minY)
                    #expect(first.maxY <= working.maxY)
                    for (index, frame) in frames.enumerated() {
                        #expect(frame.minY == first.minY)
                        #expect(frame.height == 1250)
                        #expect(frame.width > 0)
                        if index > 0 {
                            #expect(frame.minX - frames[index - 1].maxX == 12)
                        }
                    }
                }
            }
        }
    }
}

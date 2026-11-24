import OddlingsCore
import SwiftUI
import XCTest
@testable import Oddlings

/// Review 2, U3 (D-213): Die Missionstafel der Weltkarte passt ganz auf den
/// Schirm. Vorher lief sie über, die Art oben war angeschnitten und die Zeile
/// zum Volk endete mit „…“.
@MainActor
final class CampaignPanelTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("CampaignPanelTests-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func flow() throws -> AppFlow {
        let flow = AppFlow(campaign: try CampaignConfig.regionOne(), store: SaveStore(directory: directory))
        XCTAssertTrue(flow.createAvatar(race: .elves, name: "Lyra", portrait: "elf-1"))
        return flow
    }

    /// Höhe des Inhalts bei der Breite der Tafel, mit ihren Rändern.
    private func height(_ panel: MissionPanel, race: Bool, novelty: Bool) -> CGFloat {
        let inner = CampaignStyle.panelWidth - 36
        let view = panel.content(race: race, novelty: novelty).frame(width: inner)
        let size = UIHostingController(rootView: view).sizeThatFits(in: CGSize(width: inner, height: 2000))
        return size.height + 2 * CampaignStyle.panelPadding
    }

    /// Ganze Tafel mit Volk auf einem iPhone mit 393 pt Höhe quer, die knappste
    /// Fassung auf dem iPhone SE (375 pt), für jede Mission der Region.
    func testPanelFitsForEveryMission() throws {
        let flow = try flow()
        for node in flow.campaign.nodes {
            flow.selectedNode = node.id
            let panel = MissionPanel(flow: flow)
            let full = height(panel, race: true, novelty: true)
            let small = height(panel, race: false, novelty: false)
            XCTAssertLessThanOrEqual(full, 393, "\(node.id): ganze Tafel \(full) pt")
            XCTAssertLessThanOrEqual(small, 375, "\(node.id): knappe Tafel \(small) pt")
        }
    }
}

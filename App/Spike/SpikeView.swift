import SpriteKit
import SwiftUI

struct SpikeView: View {
    @State private var stats: SpikeStats
    @State private var scene: SpikeScene

    init() {
        let stats = SpikeStats()
        _stats = State(initialValue: stats)
        _scene = State(initialValue: SpikeScene(map: SpikeMap.loadMissionOne(), stats: stats))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            SpriteView(
                scene: scene,
                preferredFramesPerSecond: 60,
                options: [.ignoresSiblingOrder],
                debugOptions: [.showsFPS, .showsNodeCount, .showsDrawCount]
            )
            .ignoresSafeArea()

            hud
                .padding(12)
        }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
    }

    private var hud: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Leistungsprobe WP-01").font(.headline)
            Text("Ø \(stats.averageFPS, specifier: "%.1f") Bilder/s · längstes Bild \(stats.worstFrameMS, specifier: "%.1f") ms")
                .monospacedDigit()
            Text("\(stats.spriteCount) Figuren · HUD-Takt \(stats.updates)")
                .monospacedDigit()
            HStack {
                ForEach([100, 300, 600], id: \.self) { count in
                    Button("\(count)") { stats.targetSpriteCount = count }
                        .buttonStyle(.borderedProminent)
                        .tint(stats.targetSpriteCount == count ? .orange : .gray)
                }
                Toggle("Blitze", isOn: $stats.lightningEnabled)
                    .fixedSize()
            }
        }
        .font(.callout)
        .foregroundStyle(.white)
        .padding(10)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 12))
    }
}

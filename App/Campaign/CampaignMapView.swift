import OddlingsCore
import SwiftUI

/// Kampagnenkarte Region 1 (R-2, 07 „Kampagnenkarte"). Links die Karte mit den
/// Knoten, rechts fest die Missionstafel des gewählten Knotens. Die Karte liest
/// nur den `AppFlow`; was offen ist, entscheidet die Region im Kern.
struct CampaignMapView: View {
    let flow: AppFlow

    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                GeometryReader { proxy in
                    let rect = Self.mapRect(in: proxy.size)
                    ZStack(alignment: .topLeading) {
                        MapBackdrop(campaign: flow.campaign, rect: rect)
                        ForEach(flow.campaign.nodes, id: \.id) { node in
                            NodeButton(
                                node: node,
                                state: flow.state(of: node),
                                selected: flow.selectedNode == node.id,
                                highlighted: flow.justImproved == node.id
                            ) { flow.selectedNode = node.id }
                            .position(Self.point(node.position, in: rect))
                        }
                    }
                }
                MapHeader(flow: flow)
                    .padding(CampaignStyle.margin)
            }
            .background(CampaignStyle.forestDeep)
            MissionPanel(flow: flow)
                .frame(width: CampaignStyle.panelWidth)
        }
        .ignoresSafeArea(edges: .vertical)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("map")
    }

    /// Eingepasst statt beschnitten: Auf jedem Seitenverhältnis bleibt jeder
    /// Knoten sichtbar; was übrig bleibt, ist dunkler Waldrand.
    static func mapRect(in size: CGSize) -> CGRect {
        let available = CGSize(width: size.width, height: size.height)
        let width = min(available.width, available.height * CampaignStyle.mapAspect)
        let height = width / CampaignStyle.mapAspect
        return CGRect(x: (available.width - width) / 2, y: (available.height - height) / 2, width: width, height: height)
    }

    static func point(_ position: Point, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + position.x * rect.width, y: rect.minY + position.y * rect.height)
    }
}

// MARK: - Hintergrund

/// Gezeichneter Flüsterwald, bis das gemalte Bild im Katalog liegt. Bäume an
/// festen, aus dem Index abgeleiteten Stellen: kein Zufall, damit die Karte bei
/// jedem Öffnen gleich aussieht.
private struct MapBackdrop: View {
    let campaign: CampaignConfig
    let rect: CGRect

    var body: some View {
        ZStack(alignment: .topLeading) {
            if UIImage(named: CampaignStyle.mapImage) != nil {
                Image(CampaignStyle.mapImage)
                    .resizable()
                    .frame(width: rect.width, height: rect.height)
                    .offset(x: rect.minX, y: rect.minY)
            } else {
                Canvas { context, _ in drawForest(in: &context) }
            }
            Canvas { context, _ in drawTrails(in: &context) }
        }
        .accessibilityHidden(true)
    }

    private func at(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
        CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
    }

    private func blob(_ center: CGPoint, _ radius: CGFloat, _ color: Color, in context: inout GraphicsContext) {
        let shape = Path(ellipseIn: CGRect(x: center.x - radius * 1.3, y: center.y - radius,
                                           width: radius * 2.6, height: radius * 2))
        context.fill(shape, with: .radialGradient(Gradient(colors: [color, color.opacity(0)]),
                                                  center: center, startRadius: 0, endRadius: radius * 1.3))
    }

    private func drawForest(in context: inout GraphicsContext) {
        let frame = Path(roundedRect: rect, cornerRadius: 18)
        context.fill(frame, with: .linearGradient(Gradient(colors: [CampaignStyle.forest, CampaignStyle.forestDeep]),
                                                  startPoint: at(0.3, 0), endPoint: at(0.7, 1)))
        context.clip(to: frame)
        blob(at(0.67, 0.23), rect.height * 0.30, CampaignStyle.swamp, in: &context)
        blob(at(0.67, 0.69), rect.height * 0.30, CampaignStyle.ruins.opacity(0.8), in: &context)
        blob(at(0.90, 0.46), rect.height * 0.22, Color.black.opacity(0.35), in: &context)
        for node in campaign.nodes {
            blob(at(node.position.x, node.position.y), rect.height * 0.13, CampaignStyle.forestLight, in: &context)
        }
        // Baumkronen als dunkle Tupfen auf einem schiefen Gitter.
        let columns = 22, rows = 12
        for row in 0..<rows {
            for column in 0..<columns {
                let index = row * columns + column
                let jitterX = CGFloat((index * 37) % 11) / 11 - 0.5
                let jitterY = CGFloat((index * 53) % 7) / 7 - 0.5
                let x = (CGFloat(column) + 0.5 + jitterX * 0.8) / CGFloat(columns)
                let y = (CGFloat(row) + 0.5 + jitterY * 0.8) / CGFloat(rows)
                guard !campaign.nodes.contains(where: { abs(CGFloat($0.position.x) - x) < 0.07 && abs(CGFloat($0.position.y) - y) < 0.1 })
                else { continue }
                let radius = rect.height * (0.022 + CGFloat(index % 5) * 0.004)
                let center = at(x, y)
                context.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius * 0.8,
                                                    width: radius * 2, height: radius * 1.8)),
                             with: .color(CampaignStyle.forestDeep.opacity(0.55)))
                context.fill(Path(ellipseIn: CGRect(x: center.x - radius * 0.7, y: center.y - radius * 1.1,
                                                    width: radius * 1.4, height: radius * 1.2)),
                             with: .color(CampaignStyle.forestLight.opacity(0.35)))
            }
        }
        // Rand abdunkeln, damit der Blick auf die Lichtungen fällt.
        context.fill(frame, with: .radialGradient(Gradient(colors: [.clear, Color.black.opacity(0.45)]),
                                                  center: at(0.5, 0.5), startRadius: rect.height * 0.45,
                                                  endRadius: rect.width * 0.62))
    }

    private func drawTrails(in context: inout GraphicsContext) {
        for node in campaign.nodes {
            for previousID in node.requires {
                guard let previous = campaign.node(previousID) else { continue }
                let from = at(previous.position.x, previous.position.y)
                let to = at(node.position.x, node.position.y)
                // Leicht geschwungen, damit es nach Pfad aussieht und nicht nach Diagramm.
                let middle = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
                let normal = CGPoint(x: -(to.y - from.y) * 0.18, y: (to.x - from.x) * 0.18)
                var path = Path()
                path.move(to: from)
                path.addQuadCurve(to: to, control: CGPoint(x: middle.x + normal.x, y: middle.y + normal.y))
                context.stroke(path, with: .color(Color.black.opacity(0.35)),
                               style: StrokeStyle(lineWidth: CampaignStyle.trailWidth + 3, lineCap: .round))
                context.stroke(path, with: .color(CampaignStyle.trail.opacity(0.75)),
                               style: StrokeStyle(lineWidth: CampaignStyle.trailWidth, lineCap: .round, dash: [9, 7]))
            }
        }
    }
}

// MARK: - Kopf

private struct MapHeader: View {
    let flow: AppFlow

    var body: some View {
        HStack(spacing: 10) {
            Button { flow.showMenu() } label: {
                Label(CampaignTexts.back, systemImage: "chevron.left")
            }
            .buttonStyle(ChunkyButtonStyle(kind: .wood, height: 44, fontSize: 17))
            .accessibilityIdentifier("map.back")
            VStack(alignment: .leading, spacing: 0) {
                Text(CampaignTexts.regionLabel.uppercased())
                    .font(UITheme.bodyHeavy(12))
                    .tracking(1.5)
                    .foregroundStyle(CampaignStyle.gold)
                Text(CampaignTexts.regionName)
                    .font(UITheme.display(28))
                    .shadow(color: UITheme.outline, radius: 0, x: 0, y: 3)
            }
            HStack(spacing: 4) {
                Image(systemName: "star.fill").foregroundStyle(CampaignStyle.gold)
                Text("\(flow.progress.totalStars) / \(flow.campaign.maximumStars)")
                    .monospacedDigit()
            }
            .font(UITheme.bodyHeavy(16))
            .padding(.horizontal, 12)
            .frame(minHeight: 32)
            .background(Capsule().fill(Color.black.opacity(0.45)))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(CampaignTexts.stars(flow.progress.totalStars, of: flow.campaign.maximumStars))
            .accessibilityIdentifier("map.stars")
        }
        .foregroundStyle(UITheme.cream)
    }
}

// MARK: - Knoten

private struct NodeButton: View {
    let node: CampaignNode
    let state: CampaignNodeState
    let selected: Bool
    let highlighted: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    private var size: CGFloat {
        switch node.kind {
        case .main: CampaignStyle.mainNode
        case .boss: CampaignStyle.bossNode
        case .side: CampaignStyle.sideNode
        }
    }

    private var fill: Color {
        switch state {
        case .completed: CampaignStyle.gold
        case .open: CampaignStyle.parchment
        case .inPreparation: CampaignStyle.parchment.opacity(0.55)
        case .locked: CampaignStyle.locked
        }
    }

    private var symbol: String? {
        switch state {
        case .locked: "lock.fill"
        case .inPreparation: "hammer.fill"
        case .completed, .open: node.kind == .boss ? "crown.fill" : nil
        }
    }

    private var stars: Int {
        if case .completed(let stars) = state { stars } else { 0 }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    if state == .open {
                        shape.fill(CampaignStyle.gold.opacity(0.35))
                            .frame(width: size * 1.45, height: size * 1.45)
                            .scaleEffect(pulsing ? 1.08 : 0.9)
                            .opacity(pulsing ? 0.3 : 0.9)
                    }
                    if selected {
                        shape.stroke(Color.white, lineWidth: 3)
                            .frame(width: size + 12, height: size + 12)
                    }
                    shape.fill(CampaignStyle.woodDark).frame(width: size, height: size)
                        .shadow(color: .black.opacity(0.5), radius: 0, x: 0, y: 3)
                    shape.fill(fill).frame(width: size - CampaignStyle.ring * 2, height: size - CampaignStyle.ring * 2)
                    if let symbol {
                        Image(systemName: symbol)
                            .font(.system(size: size * 0.36, weight: .black))
                            .foregroundStyle(state == .completed(stars: stars) ? CampaignStyle.ink : CampaignStyle.woodDark.opacity(0.8))
                    } else {
                        Text(CampaignTexts.short(node.id))
                            .font(UITheme.display(size * 0.42))
                            .foregroundStyle(CampaignStyle.ink)
                    }
                }
                .frame(width: size * 1.45, height: size * 1.45)
                if case .completed = state {
                    StarRow(count: stars, size: CampaignStyle.starSize)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                        .scaleEffect(highlighted && !reduceMotion && pulsing ? 1.25 : 1)
                }
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(CampaignTexts.name(node.id))
        .accessibilityValue(CampaignTexts.accessibilityValue(state))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("map.node.\(node.id)")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: CampaignStyle.pulse).repeatForever(autoreverses: true)) { pulsing = true }
        }
    }

    private var shape: AnyShape {
        node.kind == .side ? AnyShape(Diamond()) : AnyShape(Circle())
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct StarRow: View {
    let count: Int
    let size: CGFloat

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<StarRating.maximum, id: \.self) { index in
                Image(systemName: "star.fill")
                    .font(.system(size: size, weight: .black))
                    .foregroundStyle(index < count ? CampaignStyle.gold : Color.white.opacity(0.25))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CampaignTexts.stars(count, of: StarRating.maximum))
    }
}

// MARK: - Missionstafel

/// Der Avatar über „Starten" (R-5): wer spielt und was sein Volk tut. Keine
/// Wahl mehr; das Volk ist seit dem Aufbau gesetzt (D-063).
private struct AvatarSummary: View {
    let avatar: Avatar
    let flow: AppFlow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(AvatarTexts.yourAvatar.uppercased())
                .font(UITheme.bodyHeavy(12))
                .tracking(1.5)
                .foregroundStyle(CampaignStyle.gold)
            Button { flow.openAvatar() } label: {
                AvatarBadge(avatar: avatar, rank: flow.rank, size: 40, newTalent: flow.newTalentWaiting)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("map.avatar")
            Text(CampaignTexts.raceDetail(avatar.race))
                .font(UITheme.body(13))
                .foregroundStyle(CampaignStyle.parchment)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .accessibilityIdentifier("map.race.detail")
        }
    }
}

private struct MissionPanel: View {
    let flow: AppFlow

    var body: some View {
        let node = flow.campaign.node(flow.selectedNode) ?? flow.campaign.nodes[0]
        let state = flow.state(of: node)
        VStack(alignment: .leading, spacing: 10) {
            Text(CampaignTexts.kind(node.kind).uppercased())
                .font(UITheme.bodyHeavy(12))
                .tracking(1.5)
                .foregroundStyle(CampaignStyle.gold)
            Text(CampaignTexts.name(node.id))
                .font(UITheme.display(30))
                .foregroundStyle(UITheme.cream)
                .shadow(color: UITheme.outline, radius: 0, x: 0, y: 3)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .accessibilityIdentifier("map.panel.title")
            StarRow(count: flow.progress.stars(for: node.id), size: 18)
            Text(CampaignTexts.lesson(node.id))
                .font(UITheme.body(15))
                .foregroundStyle(CampaignStyle.parchment)
                .fixedSize(horizontal: false, vertical: true)
            if let novelty = CampaignTexts.novelty(node.novelty) {
                Label(novelty, systemImage: "sparkles")
                    .font(UITheme.bodyHeavy(14))
                    .foregroundStyle(CampaignStyle.gold)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            if let avatar = flow.avatar { AvatarSummary(avatar: avatar, flow: flow) }
            Text(CampaignTexts.status(state, totalStars: flow.progress.totalStars))
                .font(UITheme.body(14))
                .foregroundStyle(state.isPlayable ? CampaignStyle.parchment : Color.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("map.panel.status")
            Button { flow.start(node.id) } label: {
                Label(state == .open || !state.isPlayable ? CampaignTexts.start : CampaignTexts.again,
                      systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ChunkyButtonStyle(kind: .gold, height: 60, fontSize: 26))
            .disabled(!state.isPlayable)
            .accessibilityIdentifier("map.start")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(
            LinearGradient(colors: [UITheme.woodFace, UITheme.wood], startPoint: .top, endPoint: .bottom)
                .overlay(alignment: .leading) { Rectangle().fill(UITheme.outline).frame(width: UITheme.line) }
                .ignoresSafeArea()
        )
        .safeAreaPadding(.trailing)
    }
}

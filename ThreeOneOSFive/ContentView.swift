import SwiftUI
import UIKit
import AVFoundation

/// Visual-only recreation of the supplied reference screen.
/// Controls update local demo state only; nothing here modifies or launches a game.
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState
    @State private var showSettings = false
    @State private var showCleaner = false
    @StateObject private var patchStore = PatchProjectStore()
    @State private var patchOperationBusy = false
    @State private var patchMessage = "READY — SELECT A PATCH"
    @State private var aimDragEnabled = false
    @State private var aimNeckEnabled = false
    @State private var hspeitoffEnabled = false
    @State private var hyperBalamagicaEnabled = false
    @State private var aimBodyPackageEnabled = false
    @State private var aimChestPackageEnabled = false
    @State private var magicEnabled = false

    @State private var selectedTab = 0
    @State private var selectedGame = 0

    @State private var aimSilent = true
    @State private var aimBot = false
    @State private var aimLine = true
    @State private var boxESP = true
    @State private var boneESP = true
    @State private var espCount = true
    @State private var weaponESP = false
    @State private var espColor = true
    @State private var fastMedikit = true
    @State private var fastFire = true

    @State private var silentFOV = 100.0
    @State private var headshot = 73.0
    @State private var lineThickness = 1.0
    @State private var fireLevel = 4
    @State private var selectedColor = "White"
    @State private var showDemoAlert = false

    var body: some View {
        ZStack {
            MockBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 17) {
                    menuTabs
                    profileHeader
                    licenseCard
                    gamePicker
                    aimingSection
                    espSection
                    combatSection
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)
                .padding(.bottom, 22)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomBar
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showCleaner) {
            CleanerView()
        }
        .sheet(item: $patchStore.passwordRequest, onDismiss: patchStore.cancelUnlock) { _ in
            PatchUnlockPrompt(store: patchStore)
        }
        .onAppear { syncPatchStates() }
        .onChange(of: scenePhase) { phase in
            guard phase == .active, !patchOperationBusy else { return }
            syncPatchStates()
            patchMessage = "READY — SELECT A PATCH"
        }
        .alert("Demo UI only", isPresented: $showDemoAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This is a visual mockup. It does not modify, inject into, or interact with Free Fire.")
        }
    }

    private var menuTabs: some View {
        HStack(spacing: 0) {
            tabButton("Menu", index: 0)
            tabButton("Log", index: 1)
        }
        .padding(3)
        .frame(height: 36)
        .background(MockPalette.tabTrack, in: RoundedRectangle(cornerRadius: 9))
    }

    private func tabButton(_ title: String, index: Int) -> some View {
        Button {
            selectedTab = index
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(selectedTab == index ? 0.96 : 0.78))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if selectedTab == index {
                        RoundedRectangle(cornerRadius: 7).fill(MockPalette.selectedTab)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var profileHeader: some View {
        HStack(spacing: 12) {
            Text("Y")
                .font(.system(size: 28, weight: .medium, design: .serif))
                .foregroundStyle(.white)
                .frame(width: 48, height: 50)
                .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 9))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(MockPalette.border, lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text("Sophia Cheat")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text("FFXC  /  PRIVATE EDITION")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.62))
                HStack(spacing: 6) {
                    Circle().fill(Color(red: 0.72, green: 0.86, blue: 0.73)).frame(width: 7, height: 7)
                    Text("Free Fire")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.66))
                }
                .padding(.top, 5)
            }

            Spacer(minLength: 4)

            Button {
                showSettings = true
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.white.opacity(0.78))
                    .frame(width: 48, height: 48)
                    .background(MockPalette.card, in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }

    private var licenseCard: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                Text("YaPa-*****-KFL")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Expires In")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.46))
                    Text("365d  3h  50m")
                        .font(.system(size: 15, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }

            HStack {
                Image(systemName: "iphone")
                    .font(.system(size: 14, weight: .regular))
                Text("iPhone 14 Pro Max")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Image(systemName: "apple.logo")
                    .font(.system(size: 13, weight: .semibold))
                Text("26.5")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(.white.opacity(0.57))
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(MockPalette.card, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(MockPalette.border, lineWidth: 1))
    }

    private var gamePicker: some View {
        HStack(spacing: 4) {
            gameButton("Free Fire", index: 0)
            gameButton("Free Fire MAX", index: 1)
        }
        .padding(4)
        .frame(height: 62)
        .background(MockPalette.card, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(MockPalette.border, lineWidth: 1))
    }

    private func gameButton(_ title: String, index: Int) -> some View {
        Button {
            selectedGame = index
        } label: {
            Text(title)
                .font(.system(size: 15, weight: selectedGame == index ? .bold : .medium))
                .foregroundStyle(selectedGame == index ? MockPalette.ink : .white.opacity(0.7))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if selectedGame == index {
                        RoundedRectangle(cornerRadius: 9).fill(MockPalette.cream)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private var aimingSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionLabel("AIMING")
            VStack(spacing: 0) {
                FeatureToggleRow(
                    symbol: "wind",
                    title: "Aim Silent",
                    subtitle: "Silent aim with headshot rate and FOV",
                    isOn: $aimSilent
                )

                Divider().overlay(MockPalette.divider)
                    .padding(.leading, 64)

                DemoSliderRow(title: "Silent FOV", value: $silentFOV, range: 0...100, suffix: "")

                Divider().overlay(MockPalette.divider)
                    .padding(.leading, 64)

                DemoSliderRow(title: "Headshot", value: $headshot, range: 0...100, suffix: "%")

                Divider().overlay(MockPalette.divider)
                    .padding(.leading, 64)

                FeatureToggleRow(
                    symbol: "scope",
                    title: "Aim Bot",
                    subtitle: "Head or neck aim with FOV mode",
                    isOn: $aimBot
                )

                Divider().overlay(MockPalette.divider)
                    .padding(.leading, 64)

                FeatureToggleRow(
                    symbol: "line.diagonal",
                    title: "Aim Line",
                    subtitle: "Line from crosshair to selected target",
                    isOn: $aimLine
                )
            }
            .background(MockPalette.card, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(MockPalette.border, lineWidth: 1))
        }
    }

    private var espSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionLabel("ESP")
            VStack(spacing: 0) {
                FeatureToggleRow(
                    symbol: "viewfinder.dashed",
                    title: "Box ESP",
                    subtitle: "Enemy bounding box",
                    isOn: $boxESP
                )

                Divider().overlay(MockPalette.divider)
                    .padding(.leading, 64)

                FeatureToggleRow(
                    symbol: "point.3.connected.trianglepath.dotted",
                    title: "Bone ESP",
                    subtitle: "Bone-line overlay",
                    isOn: $boneESP
                )

                Divider().overlay(MockPalette.divider)
                    .padding(.leading, 64)

                FeatureToggleRow(
                    symbol: "number",
                    title: "ESP Count",
                    subtitle: "Visible player count",
                    isOn: $espCount
                )

                Divider().overlay(MockPalette.divider)
                    .padding(.leading, 64)

                FeatureToggleRow(
                    symbol: "scope",
                    title: "Weapon ESP",
                    subtitle: "Weapon name above enemy box",
                    isOn: $weaponESP
                )

                Divider().overlay(MockPalette.divider)
                    .padding(.leading, 64)

                FeatureToggleRow(
                    symbol: "paintpalette",
                    title: "ESP Color",
                    subtitle: "Select ESP overlay color",
                    isOn: $espColor
                )

                Divider().overlay(MockPalette.divider)
                    .padding(.leading, 64)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("ESP Color")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Circle().fill(.white).frame(width: 14, height: 14)
                        Text(selectedColor)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Picker("ESP Color", selection: $selectedColor) {
                        Text("White").tag("White")
                        Text("Red").tag("Red")
                        Text("Green").tag("Green")
                    }
                    .pickerStyle(.menu)
                    .tint(.white.opacity(0.82))
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 9) {
                        Text("Line (thickness) px")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.66))
                            .fixedSize()
                        Slider(value: $lineThickness, in: 0...1)
                            .tint(MockPalette.cream)
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 14)
            }
            .background(MockPalette.card, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(MockPalette.border, lineWidth: 1))
        }
    }

    private var combatSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            sectionLabel("COMBAT")
            VStack(spacing: 0) {
                FeatureToggleRow(
                    symbol: "cross.case",
                    title: "Fast Medikit",
                    subtitle: "Reduce medikit use time",
                    isOn: $fastMedikit
                )

                Divider().overlay(MockPalette.divider)
                    .padding(.leading, 64)

                FeatureToggleRow(
                    symbol: "bolt.fill",
                    title: "Fast Fire",
                    subtitle: "Increase fire rate",
                    isOn: $fastFire
                )

                Divider().overlay(MockPalette.divider)
                    .padding(.leading, 15)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Fast Fire")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.68))

                    HStack(spacing: 1) {
                        ForEach(1...4, id: \.self) { level in
                            Button {
                                fireLevel = level
                            } label: {
                                Text("Lv\(level)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.white.opacity(fireLevel == level ? 0.94 : 0.75))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 34)
                                    .background {
                                        if fireLevel == level {
                                            RoundedRectangle(cornerRadius: 7).fill(MockPalette.selectedTab)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            if level < 4 {
                                Rectangle().fill(MockPalette.divider).frame(width: 1, height: 22)
                            }
                        }
                    }
                    .padding(3)
                    .background(MockPalette.tabTrack, in: RoundedRectangle(cornerRadius: 9))
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 13)
            }
            .background(MockPalette.card, in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(MockPalette.border, lineWidth: 1))
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                showDemoAlert = true
            } label: {
                Label {
                    Text("Inject Cheat")
                        .font(.system(size: 17, weight: .bold))
                } icon: {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(MockPalette.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(MockPalette.cream, in: RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)

            Button(action: resetDemoControls) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 23, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .frame(width: 60, height: 60)
                    .background(MockPalette.card, in: RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Reset demo controls")
        }
        .padding(.horizontal, 22)
        .padding(.top, 11)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white.opacity(0.45))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }

    private func resetDemoControls() {
        aimSilent = true
        aimBot = false
        aimLine = true
        boxESP = true
        boneESP = true
        espCount = true
        weaponESP = false
        espColor = true
        fastMedikit = true
        fastFire = true
        silentFOV = 100
        headshot = 73
        lineThickness = 1
        fireLevel = 4
        selectedColor = "White"
    }

    // Keep the original package-patching flow intact; the screenshot controls above
    // are visual placeholders and intentionally do not trigger these operations.
    private func syncPatchStates() {
        aimDragEnabled = isPatchActive("OGIOS File (6).3105")
        aimNeckEnabled = isPatchActive("OGIOS File (7).3105")
        hspeitoffEnabled = isPatchActive("OGIOS File (8).3105")
        hyperBalamagicaEnabled = isPatchActive("OGIOS File (10).3105")
        aimBodyPackageEnabled = isPatchActive("OGIOS File (12).3105")
        aimChestPackageEnabled = isPatchActive("OGIOS File (2).3105")
        magicEnabled = isPatchActive("OGIOS File (14).3105")
    }

    private func isPatchActive(_ packageFilename: String) -> Bool {
        patchStore.items.first(where: {
            $0.packageURL.lastPathComponent.caseInsensitiveCompare(packageFilename) == .orderedSame
        })
        .flatMap { DevicePatchService.latestReceipt(projectID: $0.id) } != nil
    }

    private enum PatchActionResult {
        case applied
        case restored
        case unavailable(String)
    }

    private func setPatchState(for packageFilename: String, enabled: Bool) {
        switch packageFilename {
        case "OGIOS File (6).3105": aimDragEnabled = enabled
        case "OGIOS File (7).3105": aimNeckEnabled = enabled
        case "OGIOS File (8).3105": hspeitoffEnabled = enabled
        case "OGIOS File (10).3105": hyperBalamagicaEnabled = enabled
        case "OGIOS File (12).3105": aimBodyPackageEnabled = enabled
        case "OGIOS File (2).3105": aimChestPackageEnabled = enabled
        case "OGIOS File (14).3105": magicEnabled = enabled
        default: break
        }
    }

    private func togglePatch(packageFilename: String, state: Binding<Bool>) {
        guard !patchOperationBusy else { return }
        guard let item = patchStore.items.first(where: {
            $0.packageURL.lastPathComponent.caseInsensitiveCompare(packageFilename) == .orderedSame
        }) else {
            patchMessage = "ERROR — PACKAGE NOT FOUND"
            log("patch: package not found: \(packageFilename)")
            return
        }

        let wasEnabled = state.wrappedValue
        patchOperationBusy = true
        patchMessage = "PROCESSING — \(packageFilename)"
        let project = item.project
        let projectID = item.id

        DispatchQueue.global(qos: .userInitiated).async {
            let result: PatchActionResult
            do {
                if wasEnabled {
                    guard let receipt = DevicePatchService.latestReceipt(projectID: projectID) else {
                        DispatchQueue.main.async {
                            self.setPatchState(for: packageFilename, enabled: false)
                            self.patchMessage = "OFF — NO ACTIVE PATCH FOUND"
                            self.patchOperationBusy = false
                        }
                        return
                    }
                    try DevicePatchService.restore(receipt: receipt)
                    result = .restored
                } else {
                    guard let project else {
                        DispatchQueue.main.async {
                            self.patchStore.requestUnlock(for: item)
                            self.patchMessage = "PASSWORD REQUIRED — ENTER PACKAGE PASSWORD"
                            self.patchOperationBusy = false
                        }
                        return
                    }
                    _ = try DevicePatchService.apply(project: project)
                    result = .applied
                }
            } catch {
                result = .unavailable("FAILED — \(String(describing: error))")
            }

            DispatchQueue.main.async {
                switch result {
                case .applied:
                    self.setPatchState(for: packageFilename, enabled: true)
                    self.patchMessage = "Inject Successful — \(packageFilename)"
                    PatchAudioFeedback.bypassActivated()
                case .restored:
                    self.setPatchState(for: packageFilename, enabled: false)
                    self.patchMessage = "Restore Successful — \(packageFilename)"
                    PatchAudioFeedback.originalRestored()
                case .unavailable(let message):
                    self.patchMessage = message
                }
                self.patchOperationBusy = false
            }
        }
    }

    private func openGame(scheme: String) {
        guard let url = URL(string: "\(scheme)://") else { return }
        UIApplication.shared.open(url, options: [:]) { success in
            log("launch: \(scheme) success=\(success)")
        }
    }
}

private struct FeatureToggleRow: View {
    let symbol: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isOn ? MockPalette.ink : .white.opacity(0.75))
                .frame(width: 50, height: 50)
                .background(isOn ? MockPalette.cream : MockPalette.iconOff, in: RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.94))
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.56))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 2)

            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .tint(MockPalette.cream)
                .scaleEffect(0.88, anchor: .trailing)
                .frame(width: 54)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

private struct DemoSliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let suffix: String

    var body: some View {
        VStack(spacing: 9) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.68))
                Spacer()
                Text("\(Int(value))\(suffix)")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.86))
            }
            Slider(value: $value, in: range)
                .tint(MockPalette.cream)
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 12)
    }
}

private struct MockBackdrop: View {
    var body: some View {
        ZStack {
            Color.black
            GeometryReader { proxy in
                Canvas { context, size in
                    var path = Path()
                    path.move(to: CGPoint(x: size.width * 0.68, y: 0))
                    path.addLine(to: CGPoint(x: size.width * 0.28, y: size.height))
                    path.move(to: CGPoint(x: size.width * 0.98, y: 0))
                    path.addLine(to: CGPoint(x: size.width * 0.58, y: size.height))
                    context.stroke(path, with: .color(.white.opacity(0.025)), lineWidth: 1)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .ignoresSafeArea()
    }
}

private enum MockPalette {
    static let cream = Color(red: 0.93, green: 0.92, blue: 0.86)
    static let ink = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let card = Color(red: 0.065, green: 0.065, blue: 0.07)
    static let border = Color(red: 0.20, green: 0.20, blue: 0.21)
    static let divider = Color(red: 0.14, green: 0.14, blue: 0.15)
    static let iconOff = Color(red: 0.12, green: 0.12, blue: 0.13)
    static let tabTrack = Color(red: 0.105, green: 0.105, blue: 0.115)
    static let selectedTab = Color(red: 0.30, green: 0.30, blue: 0.32)
}

private struct PatchOptionCard: View {
    let name: String
    let target: String
    let color: Color
    @Binding var isEnabled: Bool
    let isBusy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(color)
                    Spacer()
                    Text(isEnabled ? "ON" : "OFF")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(isEnabled ? .green : .white.opacity(0.58))
                }
                Text(name)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                Text(target)
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(color)
                HStack(spacing: 7) {
                    Circle().fill(isEnabled ? Color.green : Color.white.opacity(0.25)).frame(width: 8, height: 8)
                    Text(isEnabled ? "PATCH ACTIVE" : "ACTIVATE PATCH")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
            .padding(14)
            .background(Color.black.opacity(0.52), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(isEnabled ? color.opacity(0.85) : color.opacity(0.28), lineWidth: isEnabled ? 1.5 : 1))
            .shadow(color: isEnabled ? color.opacity(0.20) : .clear, radius: 12)
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .opacity(isBusy ? 0.55 : 1)
        .accessibilityLabel("\(name), \(target), \(isEnabled ? "On" : "Off")")
    }
}

private struct PatchAudioFeedback {
    private static let synthesizer = AVSpeechSynthesizer()
    static func bypassActivated() { speak("Bypass ativado") }
    static func originalRestored() { speak("Bypass desativado") }

    private static func speak(_ message: String) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true, options: [])
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: message)
        let voices = AVSpeechSynthesisVoice.speechVoices()
        utterance.voice = voices.first(where: {
            ($0.language.hasPrefix("pt-BR") || $0.language.hasPrefix("pt-PT") || $0.language.hasPrefix("pt")) && $0.gender == .female && $0.quality == .enhanced
        }) ?? voices.first(where: {
            $0.language.hasPrefix("pt-BR") || $0.language.hasPrefix("pt-PT") || $0.language.hasPrefix("pt")
        }) ?? AVSpeechSynthesisVoice(language: "pt-BR")
        utterance.rate = 0.43
        utterance.pitchMultiplier = 1.10
        utterance.volume = 0.90
        synthesizer.speak(utterance)
    }
}

private struct PatchUnlockPrompt: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: PatchProjectStore
    @State private var password = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Package password", text: $password)
                        .textContentType(.password)
                        .submitLabel(.done)
                        .onSubmit(unlock)
                        .onChange(of: password) { _ in store.clearUnlockError() }
                    if let errorKey = store.unlockErrorKey {
                        Text(AppLanguage.english.text(errorKey))
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text("Enter the password once to unlock this OGIOS package on this device.")
                }
            }
            .navigationTitle("Unlock package")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Unlock", action: unlock)
                        .disabled(password.isEmpty || store.isBusy)
                }
            }
        }
    }

    private func unlock() {
        guard !password.isEmpty else { return }
        store.unlock(password: password)
    }
}

struct AnimatedHyperBackdrop: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AppTheme.pageBackground
                Circle()
                    .fill(AppTheme.accent.opacity(0.12))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .offset(x: animate ? 120 : -120, y: -proxy.size.height * 0.23)
                Circle()
                    .fill(AppTheme.secondaryAccent.opacity(0.08))
                    .frame(width: 260, height: 260)
                    .blur(radius: 80)
                    .offset(x: animate ? -100 : 100, y: proxy.size.height * 0.22)
                GridOverlay()
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
        }
    }
}

private struct GridOverlay: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            let spacing: CGFloat = 44
            stride(from: CGFloat(0), through: size.width, by: spacing).forEach { x in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            stride(from: CGFloat(0), through: size.height, by: spacing).forEach { y in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(AppTheme.accent.opacity(0.055)), lineWidth: 1)
        }
    }
}

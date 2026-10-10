import SwiftUI
import UIKit
import AVFoundation

// MARK: - Delta Palette (matches reference screenshots)
private enum DeltaPalette {
    static let bg            = Color(red: 0.925, green: 0.929, blue: 0.953)   // #ECEEF4
    static let card          = Color.white
    static let purple        = Color(red: 0.482, green: 0.184, blue: 0.933)   // #7B2FBE
    static let purplePill    = Color(red: 0.486, green: 0.231, blue: 0.929)   // #7C3AED
    static let purpleBg      = Color(red: 0.941, green: 0.922, blue: 1.0)     // #F0EBFF
    static let textPrimary   = Color(red: 0.102, green: 0.102, blue: 0.180)   // #1A1A2E
    static let textSecondary = Color(red: 0.420, green: 0.447, blue: 0.502)   // #6B7280
    static let textGray      = Color(red: 0.612, green: 0.639, blue: 0.667)   // #9CA3AF
    static let toggleOff     = Color(red: 0.820, green: 0.835, blue: 0.855)   // #D1D5DB
    static let border        = Color(red: 0.898, green: 0.910, blue: 0.922)   // #E5E7EB
    static let green         = Color(red: 0.063, green: 0.725, blue: 0.506)   // #10B981
    static let red           = Color(red: 0.937, green: 0.267, blue: 0.267)   // #EF4444
    static let logBg         = Color(red: 0.110, green: 0.110, blue: 0.118)   // #1C1C1E
    static let segBg         = Color(red: 0.922, green: 0.922, blue: 0.929)   // #EBEBED
    static let cardShadow    = Color.black.opacity(0.06)
}

// MARK: - Tab enum
private enum DeltaTab: Int, CaseIterable {
    case dashboard, aimbot, visual, misc, settings

    var label: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .aimbot:    return "Aimbot"
        case .visual:    return "Visual"
        case .misc:      return "Misc"
        case .settings:  return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .aimbot:    return "scope"
        case .visual:    return "eye"
        case .misc:      return "bolt.fill"
        case .settings:  return "gearshape.fill"
        }
    }
}

// MARK: - ContentView
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var appState: AppState
    @State private var showSettings = false
    @State private var showCleaner  = false
    @StateObject private var patchStore = PatchProjectStore()
    @State private var patchOperationBusy = false
    @State private var patchMessage = "READY — SELECT A PATCH"

    // patch state
    @State private var aimDragEnabled        = false
    @State private var aimNeckEnabled        = false
    @State private var hspeitoffEnabled      = false
    @State private var hyperBalamagicaEnabled = false
    @State private var aimBodyPackageEnabled  = false
    @State private var aimChestPackageEnabled = false
    @State private var magicEnabled           = false

    // UI state — Dashboard
    @State private var antiBanEngine  = false

    // UI state — Aimbot
    @State private var launchAntiBan  = false
    @State private var aimbot         = true
    @State private var aimbotVector   = false
    @State private var aimSilent      = false
    @State private var boneIndex      = 0       // 0=Head 1=Neck 2=Body
    @State private var fieldOfView    = 120.0
    @State private var aimbotDistance = 150.0
    @State private var ignoreKnocked  = false

    // UI state — Visual
    @State private var espMaster      = false
    @State private var espLine        = false
    @State private var espBox         = false
    @State private var boxTypeIndex   = 0       // 0=Cornered 1=2D Bounding
    @State private var espName        = false
    @State private var espDistance    = false
    @State private var espHealth      = false
    @State private var healthTypeIdx  = 0       // 0=Right 1=Left
    @State private var espSkeleton    = false
    @State private var drawCountEnemies = false
    @State private var textSize       = 1.0
    @State private var thicknessSize  = 1.0

    // UI state — Misc
    @State private var noRecoil       = false
    @State private var noReload       = false
    @State private var speedHacks     = false
    @State private var speedValue     = 1.0
    @State private var fastMedkit     = false
    @State private var rapidFire      = false
    @State private var rapidValue     = 1.0

    // UI state — Settings
    @State private var streamProof    = false
    @State private var langIndex      = 0       // 0=English 1=Tiếng Việt

    // tab
    @State private var activeTab: DeltaTab = .dashboard
    @State private var showDemoAlert = false

    var body: some View {
        ZStack {
            DeltaPalette.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                topHeader
                tabContent
                deltaTabBar
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showCleaner)  { CleanerView()  }
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

    // MARK: Top Header
    private var topHeader: some View {
        HStack(spacing: 10) {
            // Logo — replace AsyncImage url with real asset as needed
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    LinearGradient(
                        colors: [Color(red:0.10,green:0.02,blue:0.20),
                                 Color(red:0.29,green:0.10,blue:0.48),
                                 DeltaPalette.purplePill],
                        startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 44, height: 44)
                .overlay(
                    Text("DELTA\nCLIENT")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                )

            Text("DELTA CLIENT")
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(DeltaPalette.textPrimary)

            Spacer()

            // FF / MAX pills
            HStack(spacing: 6) {
                Text("FF")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DeltaPalette.textPrimary)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(DeltaPalette.border, lineWidth: 1.5))

                Text("MAX")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(DeltaPalette.purplePill, in: RoundedRectangle(cornerRadius: 20))

                // Eye button
                Button { showDemoAlert = true } label: {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(DeltaPalette.purple)
                        .frame(width: 38, height: 38)
                        .background(DeltaPalette.purpleBg, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(DeltaPalette.bg)
    }

    // MARK: Tab content router
    @ViewBuilder
    private var tabContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                switch activeTab {
                case .dashboard: dashboardPage
                case .aimbot:    aimbotPage
                case .visual:    visualPage
                case .misc:      miscPage
                case .settings:  settingsPage
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 20)
        }
    }

    // MARK: - DASHBOARD PAGE
    private var dashboardPage: some View {
        VStack(spacing: 14) {
            // Welcome banner
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(DeltaPalette.purple)
                Text("Welcome DELTA back! Have a good day.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DeltaPalette.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(DeltaPalette.purpleBg, in: RoundedRectangle(cornerRadius: 16))

            // Injected Target Game
            DeltaCard {
                DeltaSectionHeader(icon: "gamecontroller.fill", title: "INJECTED TARGET GAME")
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 54, height: 54)
                        .overlay(Text("FF\nMAX").font(.system(size: 8, weight: .black)).foregroundStyle(.white).multilineTextAlignment(.center))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Free Fire MAX")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(DeltaPalette.textPrimary)
                        Text("com.dts.freefiremax")
                            .font(.system(size: 11, weight: .regular).monospaced())
                            .foregroundStyle(DeltaPalette.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 5) {
                        Circle().fill(DeltaPalette.green).frame(width: 7, height: 7)
                        Text("ACTIVE")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(DeltaPalette.green)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(DeltaPalette.green, lineWidth: 1.5))
                }
                .padding(.horizontal, 16).padding(.bottom, 16)
            }

            // Security & Anti-Ban
            DeltaCard {
                DeltaSectionHeader(icon: "shield.fill", title: "SECURITY & ANTI-BAN")
                DeltaToggleRow(label: "Anti-Ban Engine", subtitle: "Standing By", isOn: $antiBanEngine)
                // Anti-Ban Log
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("ANTI-BAN LOG")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(0.8)
                            .foregroundStyle(DeltaPalette.purple)
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(DeltaPalette.purple)
                    }
                    Text("No log yet. Open the game so the patch runs.")
                        .font(.system(size: 12).monospaced())
                        .foregroundStyle(DeltaPalette.textGray)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DeltaPalette.logBg, in: RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 16).padding(.bottom, 16)
            }

            // System Overview
            DeltaCard {
                DeltaSectionHeader(icon: "chart.bar.fill", title: "SYSTEM OVERVIEW")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    DeltaOverviewItem(icon: "cpu", value: "v3.1.5",    label: "Delta Engine")
                    DeltaOverviewItem(icon: "memorychip", value: "RW Active",  label: "Memory Hook")
                    DeltaOverviewItem(icon: "shield",     value: "Standby",    label: "Anti-Ban Mode")
                    DeltaOverviewItem(icon: "key.fill",   value: "Lifetime",   label: "License")
                }
                .padding(.horizontal, 12).padding(.bottom, 14)
            }
        }
    }

    // MARK: - AIMBOT PAGE
    private var aimbotPage: some View {
        VStack(spacing: 14) {
            // Anti-Ban
            DeltaCard {
                DeltaSectionHeader(icon: "shield.fill", title: "ANTI-BAN")
                DeltaToggleRow(label: "Launch Anti-Ban", isOn: $launchAntiBan)
            }

            // Aimbot Type
            DeltaCard {
                DeltaSectionHeader(icon: "scope", title: "AIMBOT TYPE")
                DeltaToggleRow(label: "Aimbot", isOn: $aimbot)
                DeltaDivider()
                DeltaToggleRow(label: "Aimbot Vector", isOn: $aimbotVector)
                DeltaDivider()
                DeltaToggleRow(label: "Aim Silent", isOn: $aimSilent)
                DeltaDivider()
                DeltaSegmentRow(label: "Bone:", options: ["Head", "Neck", "Body"], selection: $boneIndex)
            }

            // Aimbot Settings
            DeltaCard {
                DeltaSectionHeader(icon: "slider.horizontal.3", title: "AIMBOT SETTINGS")
                DeltaToggleRow(label: "Draw Field Of View", showColorRing: true, isOn: .constant(false))
                DeltaDivider()
                DeltaSliderRow(label: "Field Of View",    value: $fieldOfView,    range: 0...360,  unit: "",  formatInt: true)
                DeltaDivider()
                DeltaSliderRow(label: "Aimbot Distance",  value: $aimbotDistance, range: 0...500,  unit: "m", formatInt: true)
                DeltaDivider()
                DeltaToggleRow(label: "Ignore Knocked", isOn: $ignoreKnocked)
            }
        }
    }

    // MARK: - VISUAL PAGE
    private var visualPage: some View {
        VStack(spacing: 14) {
            // ESP Main
            DeltaCard {
                DeltaSectionHeader(icon: "eye.fill", title: "ESP MAIN")
                DeltaToggleRow(label: "ESP Master", isOn: $espMaster)
                DeltaDivider()
                DeltaToggleRow(label: "ESP Line",     showColorRing: true, isOn: $espLine)
                DeltaDivider()
                DeltaToggleRow(label: "ESP Box",      showColorRing: true, isOn: $espBox)
                DeltaDivider()
                DeltaSegmentRow(label: "Box Type:", options: ["Cornered", "2D Bounding"], selection: $boxTypeIndex)
                DeltaDivider()
                DeltaToggleRow(label: "ESP Name",     showColorRing: true, isOn: $espName)
                DeltaDivider()
                DeltaToggleRow(label: "ESP Distance", showColorRing: true, isOn: $espDistance)
                DeltaDivider()
                DeltaToggleRow(label: "ESP Health", isOn: $espHealth)
                DeltaDivider()
                DeltaSegmentRow(label: "Health Type:", options: ["Right", "Left"], selection: $healthTypeIdx)
                DeltaDivider()
                DeltaToggleRow(label: "ESP Skeleton",      showColorRing: true, isOn: $espSkeleton)
                DeltaDivider()
                DeltaToggleRow(label: "Draw Count Enemies", showColorRing: true, isOn: $drawCountEnemies)
            }

            // Visual Sliders
            DeltaCard {
                DeltaSectionHeader(icon: "rectangle.3.group.fill", title: "VISUAL SLIDERS")
                DeltaSliderRow(label: "Text Size",      value: $textSize,      range: 0.1...3.0, unit: "",  formatInt: false)
                DeltaDivider()
                DeltaSliderRow(label: "Thickness Size", value: $thicknessSize, range: 0.1...3.0, unit: "",  formatInt: false)
            }
        }
    }

    // MARK: - MISC PAGE
    private var miscPage: some View {
        DeltaCard {
            DeltaSectionHeader(icon: "bolt.fill", title: "MISC FEATURES")
            DeltaToggleRow(label: "No Recoil", isOn: $noRecoil)
            DeltaDivider()
            DeltaToggleRow(label: "No Reload", isOn: $noReload)
            DeltaDivider()
            DeltaToggleRow(label: "Speed Hacks", isOn: $speedHacks)
            DeltaDivider()
            DeltaSliderRow(label: "Speed",  value: $speedValue,  range: 0.1...5.0, unit: "x", formatInt: false)
            DeltaDivider()
            DeltaToggleRow(label: "Fast Medkit", isOn: $fastMedkit)
            DeltaDivider()
            DeltaToggleRow(label: "Rapid Fire", isOn: $rapidFire)
            DeltaDivider()
            DeltaSliderRow(label: "Rapid", value: $rapidValue, range: 0.1...5.0, unit: "x", formatInt: false)
        }
    }

    // MARK: - SETTINGS PAGE
    private var settingsPage: some View {
        VStack(spacing: 14) {
            // Privacy
            DeltaCard {
                DeltaSectionHeader(icon: "video.slash.fill", title: "PRIVACY")
                DeltaToggleRow(label: "Stream Proof", isOn: $streamProof)
            }

            // License Info
            DeltaCard {
                DeltaSectionHeader(icon: "key.fill", title: "LICENSE INFORMATION")
                DeltaInfoRow(label: "License:", value: "DELTA", bold: true)
                DeltaDivider()
                DeltaInfoRow(label: "Expired:", value: "Lifetime", bold: true)
                DeltaDivider()
                HStack {
                    Text("UUID:")
                        .font(.system(size: 15))
                        .foregroundStyle(DeltaPalette.textSecondary)
                    Spacer()
                    Button("Copy") {}
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 6)
                        .background(DeltaPalette.purplePill, in: RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                Text("IV-D33D9E41-0DCE-4CE8-8F01-BA0DA98001AD")
                    .font(.system(size: 11).monospaced())
                    .foregroundStyle(DeltaPalette.textSecondary)
                    .padding(.horizontal, 16).padding(.bottom, 14)
            }

            // System Compatibility
            DeltaCard {
                DeltaSectionHeader(icon: "apple.logo", title: "SYSTEM COMPATIBILITY")
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Current iOS Version:")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(DeltaPalette.textPrimary)
                        Text("iOS 27.0.0 (24A435)")
                            .font(.system(size: 13))
                            .foregroundStyle(DeltaPalette.textSecondary)
                    }
                    Spacer()
                    HStack(spacing: 5) {
                        Circle().fill(DeltaPalette.red).frame(width: 7, height: 7)
                        Text("UNSUPPORTED")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(DeltaPalette.red)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color(red:1,green:0.94,blue:0.94), in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red:1,green:0.82,blue:0.82), lineWidth: 1.5))
                }
                .padding(.horizontal, 16).padding(.bottom, 16)
            }

            // Language
            DeltaCard {
                DeltaSectionHeader(icon: "globe", title: "LANGUAGE")
                DeltaSegmentRow(label: nil, options: ["English", "Tiếng Việt"], selection: $langIndex)
            }

            // Support & System
            DeltaCard {
                DeltaSectionHeader(icon: "questionmark.circle.fill", title: "SUPPORT & SYSTEM")
                HStack(spacing: 10) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(DeltaPalette.purple)
                    Text("Discord Support")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DeltaPalette.textPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(DeltaPalette.purple)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                Divider().padding(.horizontal, 16)
                HStack(spacing: 10) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 20))
                        .foregroundStyle(DeltaPalette.red)
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DeltaPalette.red)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
            }
        }
    }

    // MARK: - Bottom Tab Bar
    private var deltaTabBar: some View {
        HStack(spacing: 0) {
            ForEach(DeltaTab.allCases, id: \.rawValue) { tab in
                Button {
                    activeTab = tab
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if activeTab == tab {
                                RoundedRectangle(cornerRadius: 17)
                                    .fill(DeltaPalette.purpleBg)
                                    .frame(width: 52, height: 34)
                            }
                            Image(systemName: tab.icon)
                                .font(.system(size: 22))
                                .foregroundStyle(activeTab == tab ? DeltaPalette.purple : DeltaPalette.textGray)
                        }
                        Text(tab.label)
                            .font(.system(size: 11, weight: activeTab == tab ? .semibold : .regular))
                            .foregroundStyle(activeTab == tab ? DeltaPalette.purple : DeltaPalette.textGray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 20)
        .background(Color.white)
        .overlay(alignment: .top) {
            Rectangle().fill(DeltaPalette.border).frame(height: 1)
        }
    }

    // MARK: - Patch logic (unchanged from original)
    private func syncPatchStates() {
        aimDragEnabled         = isPatchActive("OGIOS File (6).3105")
        aimNeckEnabled         = isPatchActive("OGIOS File (7).3105")
        hspeitoffEnabled       = isPatchActive("OGIOS File (8).3105")
        hyperBalamagicaEnabled = isPatchActive("OGIOS File (10).3105")
        aimBodyPackageEnabled  = isPatchActive("OGIOS File (12).3105")
        aimChestPackageEnabled = isPatchActive("OGIOS File (2).3105")
        magicEnabled           = isPatchActive("OGIOS File (14).3105")
    }

    private func isPatchActive(_ packageFilename: String) -> Bool {
        patchStore.items.first(where: {
            $0.packageURL.lastPathComponent.caseInsensitiveCompare(packageFilename) == .orderedSame
        })
        .flatMap { DevicePatchService.latestReceipt(projectID: $0.id) } != nil
    }

    private enum PatchActionResult { case applied, restored, unavailable(String) }

    private func setPatchState(for packageFilename: String, enabled: Bool) {
        switch packageFilename {
        case "OGIOS File (6).3105":  aimDragEnabled = enabled
        case "OGIOS File (7).3105":  aimNeckEnabled = enabled
        case "OGIOS File (8).3105":  hspeitoffEnabled = enabled
        case "OGIOS File (10).3105": hyperBalamagicaEnabled = enabled
        case "OGIOS File (12).3105": aimBodyPackageEnabled = enabled
        case "OGIOS File (2).3105":  aimChestPackageEnabled = enabled
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

// MARK: - Reusable Delta Components

private struct DeltaCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DeltaPalette.card, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: DeltaPalette.cardShadow, radius: 8, y: 2)
    }
}

private struct DeltaSectionHeader: View {
    let icon: String
    let title: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DeltaPalette.purple)
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(DeltaPalette.purple)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }
}

private struct DeltaToggleRow: View {
    let label: String
    var subtitle: String? = nil
    var showColorRing: Bool = false
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DeltaPalette.textPrimary)
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 13))
                        .foregroundStyle(DeltaPalette.textSecondary)
                }
            }
            Spacer()
            if showColorRing {
                Circle()
                    .strokeBorder(
                        AngularGradient(colors: [.red,.yellow,.green,.cyan,.blue,.purple,.red],
                                        center: .center),
                        lineWidth: 2.5
                    )
                    .frame(width: 28, height: 28)
                    .padding(.trailing, 8)
            }
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(DeltaPalette.purplePill)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

private struct DeltaSliderRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    let formatInt: Bool

    private var displayValue: String {
        formatInt ? "\(Int(value))\(unit)" : String(format: "%.1f\(unit)", value)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DeltaPalette.textPrimary)
                Spacer()
                Text(displayValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DeltaPalette.purple)
            }
            Slider(value: $value, in: range)
                .tint(DeltaPalette.purplePill)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

private struct DeltaSegmentRow: View {
    let label: String?
    let options: [String]
    @Binding var selection: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label {
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(DeltaPalette.textGray)
            }
            HStack(spacing: 0) {
                ForEach(options.indices, id: \.self) { idx in
                    Button {
                        selection = idx
                    } label: {
                        Text(options[idx])
                            .font(.system(size: 14, weight: selection == idx ? .semibold : .regular))
                            .foregroundStyle(DeltaPalette.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background {
                                if selection == idx {
                                    RoundedRectangle(cornerRadius: 7)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(DeltaPalette.segBg, in: RoundedRectangle(cornerRadius: 9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

private struct DeltaInfoRow: View {
    let label: String
    let value: String
    var bold: Bool = false
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(DeltaPalette.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: bold ? .bold : .regular))
                .foregroundStyle(DeltaPalette.textPrimary)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

private struct DeltaOverviewItem: View {
    let icon: String
    let value: String
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(DeltaPalette.purple)
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(DeltaPalette.textPrimary)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(DeltaPalette.textSecondary)
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(DeltaPalette.border, lineWidth: 1.5))
    }
}

private struct DeltaDivider: View {
    var body: some View {
        Divider()
            .background(DeltaPalette.border)
            .padding(.horizontal, 16)
    }
}

// MARK: - Unchanged supporting types

private struct PatchAudioFeedback {
    private static let synthesizer = AVSpeechSynthesizer()
    static func bypassActivated()  { speak("Bypass ativado") }
    static func originalRestored() { speak("Bypass desativado") }

    private static func speak(_ message: String) {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true, options: [])
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: message)
        let voices = AVSpeechSynthesisVoice.speechVoices()
        utterance.voice = voices.first(where: {
            ($0.language.hasPrefix("pt-BR") || $0.language.hasPrefix("pt-PT") || $0.language.hasPrefix("pt"))
                && $0.gender == .female && $0.quality == .enhanced
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
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Unlock", action: unlock).disabled(password.isEmpty || store.isBusy)
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
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) { animate = true }
            }
        }
    }
}

private struct GridOverlay: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            let spacing: CGFloat = 44
            stride(from: CGFloat(0), through: size.width,  by: spacing).forEach { x in
                path.move(to: CGPoint(x: x, y: 0)); path.addLine(to: CGPoint(x: x, y: size.height))
            }
            stride(from: CGFloat(0), through: size.height, by: spacing).forEach { y in
                path.move(to: CGPoint(x: 0, y: y)); path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(AppTheme.accent.opacity(0.055)), lineWidth: 1)
        }
    }
}

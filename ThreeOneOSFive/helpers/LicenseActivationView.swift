import SwiftUI
import UIKit

struct LicenseActivationView: View {
    @ObservedObject var manager: LicenseManager
    @State private var key = ""
    @State private var didSubmit = false
    @FocusState private var keyFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LicenseActivationBackdrop()

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 23) {
                            Spacer(minLength: 0)
                            brandHeader
                            activationCard
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: geometry.size.height)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 18)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: keyFocused) { focused in
                        guard focused else { return }
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo("activation-card", anchor: .center)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var brandHeader: some View {
        HStack(spacing: 14) {
            Text("Y")
                .font(.system(size: 40, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
                .frame(width: 68, height: 68)
                .background(Color.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.34), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text("Sophia Cheat")
                    .font(.system(size: 29, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("FFXC / PRIVATE EDITION")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .tracking(1.1)
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var activationCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "key.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(red: 0.72, green: 0.77, blue: 0.81))

                TextField("JUST ONLY CLICK", text: $key)
                    .focused($keyFocused)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit(activate)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.92))
                    .tint(ActivationPalette.cream)
                    .id("license-field")
                    .accessibilityLabel("License key")
            }
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 9))
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .stroke(ActivationPalette.border, lineWidth: 1)
            }

            Button(action: activate) {
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text(manager.isBusy ? "VALIDATING…" : "VALIDATE")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundStyle(ActivationPalette.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(ActivationPalette.cream, in: RoundedRectangle(cornerRadius: 9))
            }
            .buttonStyle(.plain)
            .disabled(manager.isBusy)

            if didSubmit, let message = manager.message {
                Text(message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(manager.isActive ? .green.opacity(0.9) : .white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            }

            if let contactOwner = manager.contactOwner,
               let contactURL = ownerURL(from: contactOwner) {
                Button("Contact Owner…") {
                    UIApplication.shared.open(contactURL)
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ActivationPalette.cream)
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(16)
        .background(Color(red: 0.045, green: 0.045, blue: 0.05), in: RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .stroke(ActivationPalette.border, lineWidth: 1)
        }
        .frame(maxWidth: 420)
        .id("activation-card")
    }

    private func activate() {
        keyFocused = false
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        didSubmit = true
        manager.activate(key: key)
    }

    private func ownerURL(from value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        if trimmed.hasPrefix("@") {
            return URL(string: "https://t.me/" + String(trimmed.dropFirst()))
        }
        return URL(string: "https://t.me/" + trimmed)
    }
}

private struct LicenseActivationBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                Canvas { context, size in
                    var grid = Path()
                    let spacing: CGFloat = 110

                    stride(from: CGFloat(0), through: size.width, by: spacing).forEach { x in
                        grid.move(to: CGPoint(x: x, y: 0))
                        grid.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    stride(from: CGFloat(0), through: size.height, by: spacing).forEach { y in
                        grid.move(to: CGPoint(x: 0, y: y))
                        grid.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(grid, with: .color(.white.opacity(0.018)), lineWidth: 1)

                    var diagonal = Path()
                    diagonal.move(to: CGPoint(x: size.width * 0.98, y: size.height * 0.37))
                    diagonal.addLine(to: CGPoint(x: size.width * 0.68, y: size.height))
                    context.stroke(diagonal, with: .color(.white.opacity(0.025)), lineWidth: 1)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea()
    }
}

private enum ActivationPalette {
    static let cream = Color(red: 0.94, green: 0.93, blue: 0.87)
    static let ink = Color(red: 0.06, green: 0.06, blue: 0.06)
    static let border = Color(red: 0.22, green: 0.22, blue: 0.23)
}

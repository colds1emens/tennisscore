import SwiftUI
import SwiftData
import TennisEngine

/// Настройки: значения очков «105», пресеты, тема.
struct SettingsView: View {
    @Environment(AppRouter.self) private var router
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \RulePreset.createdAt) private var presets: [RulePreset]

    @State private var showSavePreset = false
    @State private var presetName = ""
    @State private var renamingPreset: RulePreset?
    @State private var renameText = ""

    private var theme: CourtTheme { settings.theme }

    var body: some View {
        @Bindable var settings = settings

        ZStack {
            CourtBackground(theme: theme)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    ScreenHeader(title: "Settings", subtitle: nil, theme: theme) {
                        router.path.removeLast()
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            sectionLabel("Points in “105”")
                            CategoryListEditor(categories: $settings.categories, theme: theme)
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            sectionLabel("Presets")
                            presetRows
                            Button {
                                presetName = ""
                                showSavePreset = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Save current values")
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                }
                                .foregroundStyle(theme.accent)
                                .brightness(0.2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(SpringPressStyle())
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 12) {
                            sectionLabel("Default theme")
                            ThemePicker(selection: $settings.theme)
                        }
                    }

                    GlassCard(theme: theme) {
                        VStack(spacing: 8) {
                            sectionLabel("About")
                            HStack {
                                TennisBall(size: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Winner 105")
                                        .font(.system(.body, design: .rounded).weight(.bold))
                                        .foregroundStyle(theme.textPrimary)
                                    Text("Match and practice scoring · offline")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(theme.textSecondary)
                                }
                                Spacer()
                                Text(Bundle.main.appVersionString)
                                    .font(.system(.footnote, design: .rounded).monospacedDigit())
                                    .foregroundStyle(theme.textSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .readableWidth()
            }
        }
        .alert("Preset name", isPresented: $showSavePreset) {
            TextField("My club", text: $presetName)
            Button("Save") { savePreset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Current point values will be saved as a preset")
        }
        .alert("Rename preset", isPresented: Binding(get: { renamingPreset != nil }, set: { if !$0 { renamingPreset = nil } })) {
            TextField("Preset name", text: $renameText)
            Button("Save") {
                let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                if let preset = renamingPreset, !trimmed.isEmpty {
                    preset.name = trimmed
                    Haptics.success()
                }
                renamingPreset = nil
            }
            Button("Cancel", role: .cancel) { renamingPreset = nil }
        }
    }

    // MARK: - Пресеты

    private var presetRows: some View {
        VStack(spacing: 8) {
            builtInPresetRow(
                name: "Classic 1/5/10/20",
                categories: PointCategory.standardSet()
            )
            ForEach(presets) { preset in
                presetRow(preset)
            }
        }
    }

    private func builtInPresetRow(name: String, categories: [PointCategory]) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundStyle(CourtTheme.ballYellow)
            Text(name)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(theme.textPrimary)
            Spacer()
            applyButton {
                withAnimation(.spring(duration: 0.3)) {
                    settings.categories = categories
                }
            }
        }
    }

    private func presetRow(_ preset: RulePreset) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 12))
                .foregroundStyle(theme.accent)
                .brightness(0.2)
            Text(preset.name)
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(theme.textPrimary)
                .lineLimit(1)
            Spacer()
            applyButton {
                withAnimation(.spring(duration: 0.3)) {
                    settings.categories = preset.categories
                }
            }
            Button {
                renamingPreset = preset
                renameText = preset.name
            } label: {
                Image(systemName: "pencil")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 30, height: 32)
            }
            .buttonStyle(SpringPressStyle())
            .accessibilityLabel("Rename preset \(preset.name)")
            Button {
                modelContext.delete(preset)
                Haptics.warning()
            } label: {
                Image(systemName: "trash")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(theme.textSecondary)
                    .frame(width: 30, height: 32)
            }
            .buttonStyle(SpringPressStyle())
            .accessibilityLabel("Delete preset \(preset.name)")
        }
    }

    private func applyButton(action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.selection()
        } label: {
            Text("Apply")
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(theme.accent)
                .brightness(0.2)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(theme.cardFill))
                .overlay(Capsule().strokeBorder(theme.cardStroke, lineWidth: 1))
        }
        .buttonStyle(SpringPressStyle())
    }

    private func savePreset() {
        let trimmed = presetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        modelContext.insert(RulePreset(name: trimmed, categories: settings.categories))
        Haptics.success()
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text.uppercased())
                .font(.system(.caption, design: .rounded).weight(.bold))
                .tracking(1.5)
                .foregroundStyle(theme.textSecondary)
            Spacer()
        }
    }
}

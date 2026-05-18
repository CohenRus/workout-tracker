//
//  SettingsView.swift
//  Tracker
//

import SwiftUI

// Shared with [`ContentView`](ContentView.swift) for persisted scope.
enum CalendarScope: String, CaseIterable {
    case month = "Month"
    case week = "Week"
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(WorkoutLabelStore.self) private var labelStore
    @Environment(WorkoutStore.self) private var workoutStore

    @AppStorage("calendarScope") private var calendarScopeRaw = CalendarScope.month.rawValue
    @AppStorage("appAppearance") private var appearanceRaw = AppAppearance.light.rawValue

    @State private var editorRoute: LabelEditorRoute?
    @State private var deleteTarget: WorkoutLabel?

    private var calendarScopeBinding: Binding<CalendarScope> {
        Binding(
            get: { CalendarScope(rawValue: calendarScopeRaw) ?? .month },
            set: { calendarScopeRaw = $0.rawValue }
        )
    }

    private var appearanceBinding: Binding<AppAppearance> {
        Binding(
            get: { AppAppearance(rawValue: appearanceRaw) ?? .light },
            set: { appearanceRaw = $0.rawValue }
        )
    }

    private var resolvedAppearancePreference: ColorScheme? {
        (AppAppearance(rawValue: appearanceRaw) ?? .light).preferredColorScheme
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        editorRoute = .add
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                            Text("Add workout label")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .foregroundStyle(AppTheme.ink)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Add workout label")

                    ForEach(labelStore.labels) { label in
                        Button {
                            editorRoute = .edit(label)
                        } label: {
                            LabelRowStripe(label: label)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteTarget = label
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    sectionTitle("Workout labels")
                }
                .listRowBackground(AppTheme.surface)

                Section {
                    Picker("", selection: calendarScopeBinding) {
                        ForEach(CalendarScope.allCases, id: \.self) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.accentColor)
                    .journalScopeChrome()
                    .accessibilityLabel("Calendar view")
                } header: {
                    sectionTitle("Calendar view")
                }
                .listRowBackground(AppTheme.surface)

                Section {
                    Picker("", selection: appearanceBinding) {
                        ForEach(AppAppearance.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(Color.accentColor)
                    .journalScopeChrome()
                    .accessibilityLabel("Appearance")
                } header: {
                    sectionTitle("Appearance")
                }
                .listRowBackground(AppTheme.surface)
            }
            .listSectionSpacing(24)
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.journalBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                }
            }
            .toolbarBackground(AppTheme.surface.opacity(0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(item: $editorRoute) { route in
                LabelEditorSheet(route: route) { saved in
                    labelStore.upsert(saved)
                }
            }
            .sheet(item: $deleteTarget) { label in
                LabelDeletionSheet(label: label)
            }
        }
        .preferredColorScheme(resolvedAppearancePreference)
    }

    private func sectionTitle(_ text: String) -> some View {
        let alpha = colorScheme == .dark ? 0.93 : 0.88
        return Text(text)
            .font(.system(.callout, design: .rounded, weight: .semibold))
            .foregroundStyle(AppTheme.ink.opacity(alpha))
    }
}

// MARK: - Label row

private struct LabelRowStripe: View {
    @Environment(\.colorScheme) private var colorScheme
    let label: WorkoutLabel

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            label.stripeColor,
                            label.stripeColor.opacity(AppTheme.labelStripeBarBottomBlend(for: colorScheme)),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 5, height: 36)
                .overlay {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(AppTheme.hairline, lineWidth: 0.5)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(label.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppTheme.ink)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.inkMuted)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// MARK: - Editor

enum LabelEditorRoute: Identifiable {
    case add
    case edit(WorkoutLabel)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let label): return label.id.uuidString
        }
    }
}

private struct LabelEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    let route: LabelEditorRoute
    let onSave: (WorkoutLabel) -> Void

    @State private var labelId: UUID
    @State private var name: String
    @State private var colorHex: String
    @State private var labelPendingDeletion: WorkoutLabel?
    @State private var showDeleteConfirmation = false

    init(route: LabelEditorRoute, onSave: @escaping (WorkoutLabel) -> Void) {
        self.route = route
        self.onSave = onSave
        switch route {
        case .add:
            _labelId = State(initialValue: UUID())
            _name = State(initialValue: "")
            _colorHex = State(initialValue: WorkoutHexColor.presetPalette[0])
        case .edit(let label):
            _labelId = State(initialValue: label.id)
            _name = State(initialValue: label.name)
            _colorHex = State(initialValue: WorkoutHexColor.normalizedHex6(label.colorHex) ?? WorkoutHexColor.presetPalette[0])
        }
        _labelPendingDeletion = State(initialValue: nil)
        _showDeleteConfirmation = State(initialValue: false)
    }

    private var pickerColorBinding: Binding<Color> {
        Binding(
            get: {
                guard let normalized = WorkoutHexColor.normalizedHex6(colorHex) else {
                    return WorkoutHexColor.color(hex6: WorkoutHexColor.presetPalette[0])
                }
                return WorkoutHexColor.color(hex6: normalized)
            },
            set: { newColor in
                if let h = WorkoutHexColor.hex6(from: newColor) {
                    colorHex = h
                }
            }
        )
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && WorkoutHexColor.normalizedHex6(colorHex) != nil
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Name", text: $name)
                        .font(.system(.body, design: .rounded))
                        .textInputAutocapitalization(.words)
                        .onChange(of: name) { _, newValue in
                            if newValue.count > AppConstants.maxLabelNameLength {
                                name = String(newValue.prefix(AppConstants.maxLabelNameLength))
                            }
                        }
                } header: {
                    editorSectionTitle("Name")
                }
                .listRowBackground(AppTheme.surface)

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 10) {
                        ForEach(Array(WorkoutHexColor.presetPalette.enumerated()), id: \.offset) { pair in
                            let idx = pair.offset + 1
                            let hex = pair.element
                            let selected = WorkoutHexColor.normalizedHex6(colorHex)?.uppercased() == hex.uppercased()

                            Button {
                                colorHex = hex
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(WorkoutHexColor.color(hex6: hex))
                                        .frame(width: 36, height: 36)
                                        .shadow(color: Color.black.opacity(0.08), radius: selected ? 4 : 2, y: selected ? 2 : 1)
                                        .overlay {
                                            Circle().strokeBorder(
                                                selected ? AppTheme.chromeRim : AppTheme.hairline,
                                                lineWidth: selected ? 2 : 0.75
                                            )
                                        }
                                    if selected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(Color.white)
                                            .shadow(color: Color.black.opacity(0.35), radius: 1, y: 1)
                                            .offset(x: 12, y: -12)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Preset color \(idx) of \(WorkoutHexColor.presetPalette.count)")
                            .accessibilityAddTraits(selected ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)

                    ColorPicker("Custom color", selection: pickerColorBinding, supportsOpacity: false)
                        .font(.system(.body, design: .rounded))

                    HStack(spacing: 10) {
                        Text("#")
                            .font(.system(.body, design: .monospaced, weight: .semibold))
                            .foregroundStyle(AppTheme.inkMuted)
                        TextField("RRGGBB", text: $colorHex)
                            .font(.system(.body, design: .monospaced))
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .onChange(of: colorHex) { _, newValue in
                                let upper = newValue.uppercased().filter(\.isHexDigit)
                                let clipped = String(upper.prefix(6))
                                if clipped != colorHex {
                                    colorHex = clipped
                                }
                            }
                    }
                } header: {
                    editorSectionTitle("Color")
                } footer: {
                    Text("Tip: enter a hex value like `#3A6288`, or tune with the picker above.")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(AppTheme.inkMuted)
                }
                .listRowBackground(AppTheme.surface)

                if case .edit(let original) = route {
                    Section {
                        Button(role: .destructive) {
                            labelPendingDeletion = WorkoutLabel(
                                id: original.id,
                                name: trimmedName.isEmpty ? original.name : trimmedName,
                                colorHex: WorkoutHexColor.normalizedHex6(colorHex) ?? original.colorHex
                            )
                            showDeleteConfirmation = true
                        } label: {
                            Text("Delete label…")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .accessibilityHint("Opens options to remove this label and its calendar entries.")
                    } footer: {
                        Text("You can also swipe left on the label in the list to delete.")
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(AppTheme.inkMuted)
                    }
                    .listRowBackground(AppTheme.surface)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.journalBackground.ignoresSafeArea())
            .navigationTitle(navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .disabled(!canSave)
                }
            }
            .toolbarBackground(AppTheme.surface.opacity(0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showDeleteConfirmation, onDismiss: { labelPendingDeletion = nil }) {
                if let deleteLabel = labelPendingDeletion {
                    LabelDeletionSheet(label: deleteLabel, onSuccessfulDelete: {
                        dismiss()
                    })
                }
            }
        }
    }

    private var navTitle: String {
        switch route {
        case .add: return "New label"
        case .edit: return "Edit label"
        }
    }

    private func editorSectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(AppTheme.inkMuted)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    private func save() {
        guard let hex = WorkoutHexColor.normalizedHex6(colorHex) else { return }
        let label = WorkoutLabel(id: labelId, name: trimmedName, colorHex: hex)
        onSave(label)
        dismiss()
    }
}

// MARK: - Delete label

private struct LabelDeletionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WorkoutLabelStore.self) private var labelStore
    @Environment(WorkoutStore.self) private var workoutStore

    let label: WorkoutLabel
    /// Called after the label (and optional entries) are removed; not called on Cancel.
    var onSuccessfulDelete: (() -> Void)? = nil

    @State private var reassignToId: UUID?

    private var entryCount: Int {
        workoutStore.logCount(forLabelId: label.id)
    }

    private var otherLabels: [WorkoutLabel] {
        labelStore.labels.filter { $0.id != label.id }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(deleteExplainer)
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(AppTheme.ink)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
                }
                .listRowBackground(AppTheme.surface)

                if entryCount > 0, !otherLabels.isEmpty {
                    Section {
                        Picker("Move entries to", selection: $reassignToId) {
                            ForEach(otherLabels) { target in
                                Text(target.name).tag(Optional(target.id))
                            }
                        }
                        .font(.system(.body, design: .rounded))

                        Button {
                            guard let to = reassignToId else { return }
                            workoutStore.reassignLabel(from: label.id, to: to)
                            labelStore.removeDefinition(id: label.id)
                            onSuccessfulDelete?()
                            dismiss()
                        } label: {
                            Text("Move entries and remove label")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .buttonStyle(.borderedProminent)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 6, trailing: 16))
                    } header: {
                        editorSectionTitle("Reassign")
                    }
                    .listRowBackground(AppTheme.surface)
                }

                if entryCount > 0 {
                    Section {
                        Button(role: .destructive) {
                            workoutStore.removeLogs(withLabelId: label.id)
                            labelStore.removeDefinition(id: label.id)
                            onSuccessfulDelete?()
                            dismiss()
                        } label: {
                            Text("Delete all entries and remove label")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .accessibilityHint("Deletes every workout logged with this label, then removes the label.")
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 10, trailing: 16))
                    }
                    .listRowBackground(AppTheme.surface)
                }

                if entryCount == 0 {
                    Section {
                        Button(role: .destructive) {
                            labelStore.removeDefinition(id: label.id)
                            onSuccessfulDelete?()
                            dismiss()
                        } label: {
                            Text("Remove label")
                                .font(.system(.body, design: .rounded, weight: .semibold))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    }
                    .listRowBackground(AppTheme.surface)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.journalBackground.ignoresSafeArea())
            .navigationTitle("Delete label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
            }
            .toolbarBackground(AppTheme.surface.opacity(0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                if reassignToId == nil {
                    reassignToId = otherLabels.first?.id
                }
            }
        }
    }

    private var deleteExplainer: String {
        if entryCount == 0 {
            return "Remove “\(label.name)”?"
        }
        if otherLabels.isEmpty {
            return "“\(label.name)” is used on \(entryCount) entries and this is your only label. Continuing will permanently delete those entries along with this label."
        }
        return "Deleting “\(label.name)” affects \(entryCount) entries on your calendar. You can move those entries to another label, or delete the entries outright."
    }

    private func editorSectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(AppTheme.inkMuted)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

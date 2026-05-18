//
//  DayLogsSheet.swift
//  Tracker
//

import SwiftUI

struct DayLogsSheet: View {
    @Environment(WorkoutStore.self) private var store
    @Environment(WorkoutLabelStore.self) private var labelStore
    @Environment(\.colorScheme) private var colorScheme
    let date: Date
    @Environment(\.dismiss) private var dismiss
    @State private var draftLabelId: UUID?
    @State private var draftDetails = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.logs(on: date)) { log in
                        loggedEntryRow(for: log)
                    }
                } header: {
                    Text("Logged")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.inkMuted)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .listRowBackground(AppTheme.surface)

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pick a label, optionally add details, then confirm.")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(AppTheme.inkMuted)

                        labelPickerGrid

                        TextField("Description", text: $draftDetails)
                            .textInputAutocapitalization(.sentences)
                            .font(.system(.body, design: .rounded))

                        HStack {
                            Spacer(minLength: 0)
                            Text("\(draftDetails.count)/\(AppConstants.maxWorkoutDetailLength)")
                                .font(.system(.caption2, design: .rounded, weight: .medium))
                                .foregroundStyle(AppTheme.inkMuted)
                        }

                        HStack(spacing: 10) {
                            Button("Cancel") {
                                clearDraft()
                            }
                            .frame(maxWidth: .infinity)
                            .font(.system(.body, design: .rounded, weight: .semibold))

                            Button("Confirm") {
                                confirmDraft()
                            }
                            .frame(maxWidth: .infinity)
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .buttonStyle(.borderedProminent)
                            .disabled(!canConfirmNewEntry)
                        }
                    }
                    .padding(.vertical, 6)
                    .onChange(of: draftDetails) { _, newValue in
                        let maxLen = AppConstants.maxWorkoutDetailLength
                        if newValue.count > maxLen {
                            draftDetails = String(newValue.prefix(maxLen))
                        }
                    }
                } header: {
                    Text("New entry")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppTheme.inkMuted)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .listRowBackground(AppTheme.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppTheme.journalBackground.ignoresSafeArea())
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
            }
            .toolbarBackground(AppTheme.surface.opacity(0.92), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    @ViewBuilder
    private func loggedEntryRow(for log: WorkoutLog) -> some View {
        let resolved = WorkoutLabelResolution.stripe(for: log, labelStore: labelStore, colorScheme: colorScheme)
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(resolved.color)
                .frame(width: 10, height: 10)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 3) {
                Text(resolved.title)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(AppTheme.ink)
                let noteLine = trimmedNote(log.details)
                if !noteLine.isEmpty {
                    Text(noteLine)
                        .font(.system(.caption, design: .rounded, weight: .regular))
                        .foregroundStyle(AppTheme.inkMuted)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.remove(id: log.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .accessibilityLabel("Delete \(resolved.title)")
        }
    }

    private var labelPickerGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 148), spacing: 10)], spacing: 10) {
            ForEach(labelStore.labels) { label in
                let selected = draftLabelId == label.id
                Button {
                    draftLabelId = label.id
                } label: {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(
                                label.stripeColor.opacity(
                                    AppTheme.labelPickerBarOpacity(selected: selected, colorScheme: colorScheme)
                                )
                            )
                            .frame(width: selected ? 5 : 4, height: selected ? 30 : 28)
                            .overlay {
                                if selected {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .strokeBorder(Color.accentColor.opacity(0.55), lineWidth: 1)
                                }
                            }
                        Text(label.name)
                            .font(.system(.subheadline, design: .rounded).weight(selected ? .bold : .semibold))
                            .foregroundStyle(selected ? AppTheme.ink : AppTheme.inkMuted)
                        Spacer(minLength: 0)
                        if selected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                                .accessibilityHidden(true)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, selected ? 11 : 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerChip, style: .continuous)
                            .fill(
                                label.stripeColor.opacity(
                                    AppTheme.labelPickerFillOpacity(selected: selected, colorScheme: colorScheme)
                                )
                            )
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: AppTheme.cornerChip, style: .continuous)
                            .strokeBorder(
                                selected
                                    ? Color.accentColor.opacity(colorScheme == .dark ? 0.92 : 0.78)
                                    : label.stripeColor.opacity(
                                        AppTheme.labelPickerStrokeOpacity(selected: selected, colorScheme: colorScheme)
                                    ),
                                lineWidth: selected ? 2.25 : 1
                            )
                    }
                    .shadow(
                        color: selected ? Color.accentColor.opacity(colorScheme == .dark ? 0.28 : 0.18) : .clear,
                        radius: selected ? 8 : 0,
                        y: selected ? 2 : 0
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label.name + (selected ? ", selected" : ""))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private func trimmedNote(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func clearDraft() {
        draftLabelId = nil
        draftDetails = ""
    }

    private func confirmDraft() {
        guard let id = draftLabelId else { return }
        store.add(day: date, labelId: id, details: draftDetails)
        clearDraft()
    }

    private var dateTitle: String {
        date.formatted(.dateTime.month(.abbreviated).day().year())
    }

    private var canConfirmNewEntry: Bool {
        guard let id = draftLabelId else { return false }
        return labelStore.label(id: id) != nil
    }
}

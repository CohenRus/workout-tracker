//
//  WorkoutLabels.swift
//  Tracker
//

import Dispatch
import Foundation
import Observation
import os
import SwiftUI
import UIKit

private let labelsPersistenceLog = Logger(subsystem: AppConstants.bundleLoggerSubsystem, category: "LabelsPersistence")

// MARK: - Color / hex

enum WorkoutHexColor {
    /// Preset tones for the palette grid (readable on paper and dark panels).
    static let presetPalette: [String] = [
        "8B6048",
        "A88662",
        "5A8C52",
        "3E9078",
        "4E84C4",
        "4A78B8",
        "9A58A8",
        "C85E88",
        "E07050",
        "E8A028",
    ]

    private static func scrubHex(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
            .uppercased()
    }

    static func normalizedHex6(_ raw: String) -> String? {
        let h = scrubHex(raw)
        guard h.count == 6, h.allSatisfy({ $0.isHexDigit }) else { return nil }
        return h.uppercased()
    }

    static func color(hex6: String) -> Color {
        guard let normalized = normalizedHex6(hex6),
              let v = UInt32(normalized, radix: 16) else {
            return Color(red: 0.55, green: 0.55, blue: 0.55)
        }
        let r = Double((v >> 16) & 0xFF) / 255.0
        let g = Double((v >> 8) & 0xFF) / 255.0
        let b = Double(v & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }

    static func hex6(from color: Color) -> String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        let ui = UIColor(color)
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let rr = Int(round(r * 255)) & 0xFF
        let gg = Int(round(g * 255)) & 0xFF
        let bb = Int(round(b * 255)) & 0xFF
        return String(format: "%02X%02X%02X", rr, gg, bb)
    }
}

// MARK: - Legacy migration UUIDs

/// Stable IDs so `workouts.json` rows migrated from enum `WorkoutKind` align with seeded labels.
enum WorkoutLegacyLabelUUID {
    static let climbUUID = UUID(uuidString: "6E8BC9D0-A9F1-4E2D-9C43-000000000001")!
    static let liftUUID = UUID(uuidString: "6E8BC9D0-A9F1-4E2D-9C43-000000000002")!
    static let stretchUUID = UUID(uuidString: "6E8BC9D0-A9F1-4E2D-9C43-000000000003")!
    static let runUUID = UUID(uuidString: "6E8BC9D0-A9F1-4E2D-9C43-000000000004")!
    static let hikeUUID = UUID(uuidString: "6E8BC9D0-A9F1-4E2D-9C43-000000000005")!
}

extension WorkoutKind {
    var migrationLabelUUID: UUID {
        switch self {
        case .climb: return WorkoutLegacyLabelUUID.climbUUID
        case .lift: return WorkoutLegacyLabelUUID.liftUUID
        case .stretch: return WorkoutLegacyLabelUUID.stretchUUID
        case .run: return WorkoutLegacyLabelUUID.runUUID
        case .hike: return WorkoutLegacyLabelUUID.hikeUUID
        }
    }
}

// MARK: - Model

struct WorkoutLabel: Identifiable, Codable, Hashable {
    var id: UUID
    /// Display name.
    var name: String
    /// Six hex digits, e.g. `9466D1` (no `#`).
    var colorHex: String

    var stripeColor: Color {
        WorkoutHexColor.color(hex6: colorHex)
    }

    var displayHex: String {
        if let n = WorkoutHexColor.normalizedHex6(colorHex) { return "#\(n)" }
        return "#———"
    }

    static func bootstrapLabels() -> [WorkoutLabel] {
        [
            WorkoutLabel(id: WorkoutLegacyLabelUUID.climbUUID, name: "Climb", colorHex: "9466D1"),
            WorkoutLabel(id: WorkoutLegacyLabelUUID.liftUUID, name: "Lift", colorHex: "DB6B52"),
            WorkoutLabel(id: WorkoutLegacyLabelUUID.stretchUUID, name: "Stretch", colorHex: "669E94"),
            WorkoutLabel(id: WorkoutLegacyLabelUUID.runUUID, name: "Run", colorHex: "3885EB"),
            WorkoutLabel(id: WorkoutLegacyLabelUUID.hikeUUID, name: "Hike", colorHex: "5C9461"),
        ]
    }
}

// MARK: - Store

@Observable
final class WorkoutLabelStore {
    private(set) var labels: [WorkoutLabel] = []
    private let fileURL: URL
    private var pendingSaveWorkItem: DispatchWorkItem?

    init() {
        if let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dir = support.appendingPathComponent(AppConstants.applicationSupportSubdirectory, isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                labelsPersistenceLog.error("Application Support subdirectory failed to create: \(error.localizedDescription)")
            }
            fileURL = dir.appendingPathComponent(AppConstants.labelsFileName)
        } else {
            labelsPersistenceLog.critical("Application Support URL unavailable — using temp for labels.")
            let dir = FileManager.default.temporaryDirectory.appendingPathComponent(AppConstants.applicationSupportSubdirectory, isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            fileURL = dir.appendingPathComponent(AppConstants.labelsFileName)
        }
        load()
    }

    deinit {
        pendingSaveWorkItem?.cancel()
        writeToDiskNow()
    }

    func label(id: UUID) -> WorkoutLabel? {
        labels.first { $0.id == id }
    }

    func upsert(_ label: WorkoutLabel) {
        if let i = labels.firstIndex(where: { $0.id == label.id }) {
            labels[i] = label
        } else {
            labels.append(label)
        }
        scheduleSave()
    }

    func removeDefinition(id: UUID) {
        labels.removeAll { $0.id == id }
        scheduleSave()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            labels = Self.bootstrapSeed()
            writeToDiskNow()
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([WorkoutLabel].self, from: data)
            labels = decoded
            if labels.isEmpty {
                labels = Self.bootstrapSeed()
                writeToDiskNow()
            }
        } catch {
            labelsPersistenceLog.error("Load labels failed: \(error.localizedDescription)")
            labels = Self.bootstrapSeed()
            writeToDiskNow()
        }
    }

    /// First launch or recovery: seeded defaults matching legacy `WorkoutKind`.
    private static func bootstrapSeed() -> [WorkoutLabel] {
        WorkoutLabel.bootstrapLabels()
    }

    private func scheduleSave() {
        pendingSaveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.writeToDiskNow()
            self?.pendingSaveWorkItem = nil
        }
        pendingSaveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + .nanoseconds(Int(AppConstants.persistenceDebounceNanoseconds)), execute: work)
    }

    private func writeToDiskNow() {
        do {
            let data = try JSONEncoder().encode(labels)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            labelsPersistenceLog.error("Save labels failed: \(error.localizedDescription)")
        }
    }
}

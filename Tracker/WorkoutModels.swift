//
//  WorkoutModels.swift
//  Tracker
//

import Foundation
import SwiftUI

// MARK: - Model

enum WorkoutKind: String, Codable, CaseIterable, Identifiable, Hashable {
    case climb, lift, stretch, run, hike

    var id: String { rawValue }

    var label: String {
        switch self {
        case .climb: return "Climb"
        case .lift: return "Lift"
        case .stretch: return "Stretch"
        case .run: return "Run"
        case .hike: return "Hike"
        }
    }

    var stripeColor: Color {
        switch self {
        case .climb: return Color(red: 0.58, green: 0.40, blue: 0.82)
        case .lift: return Color(red: 0.86, green: 0.42, blue: 0.32)
        case .stretch: return Color(red: 0.40, green: 0.62, blue: 0.58)
        case .run: return Color(red: 0.22, green: 0.52, blue: 0.92)
        case .hike: return Color(red: 0.36, green: 0.58, blue: 0.38)
        }
    }

    static func matching(legacyTitle: String) -> WorkoutKind {
        let s = legacyTitle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let k = WorkoutKind(rawValue: s) { return k }
        // Prefer longer raw values first so e.g. "stretch" wins over a substring like "run".
        for k in WorkoutKind.allCases.sorted(by: { $0.rawValue.count > $1.rawValue.count }) {
            if s.contains(k.rawValue) { return k }
        }
        return .lift
    }
}

struct WorkoutLog: Identifiable, Codable, Hashable {
    var id: UUID
    var day: Date
    /// References `WorkoutLabel.id` in `WorkoutLabelStore`.
    var labelId: UUID
    /// User-entered note shown under the activity type (day sheet).
    var details: String

    enum CodingKeys: String, CodingKey {
        case id, day, labelId, kind, title, details
    }

    init(id: UUID, day: Date, labelId: UUID, details: String = "") {
        self.id = id
        self.day = day
        self.labelId = labelId
        self.details = details
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        day = try c.decode(Date.self, forKey: .day)
        if let lid = try? c.decode(UUID.self, forKey: .labelId) {
            labelId = lid
        } else if let k = try? c.decode(WorkoutKind.self, forKey: .kind) {
            labelId = k.migrationLabelUUID
        } else if let t = try? c.decode(String.self, forKey: .title) {
            labelId = WorkoutKind.matching(legacyTitle: t).migrationLabelUUID
        } else {
            labelId = WorkoutKind.lift.migrationLabelUUID
        }
        details = try c.decodeIfPresent(String.self, forKey: .details) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(day, forKey: .day)
        try c.encode(labelId, forKey: .labelId)
        try c.encode(details, forKey: .details)
    }
}

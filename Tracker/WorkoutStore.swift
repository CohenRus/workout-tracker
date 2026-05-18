//
//  WorkoutStore.swift
//  Tracker
//

import Dispatch
import Foundation
import Observation
import os

private let workoutPersistenceLog = Logger(subsystem: AppConstants.bundleLoggerSubsystem, category: "WorkoutPersistence")

@Observable
final class WorkoutStore {
    /// Logs grouped by calendar start-of-day; keys always `Calendar.current.startOfDay(for:)`.
    private var logsByDay: [Date: [WorkoutLog]] = [:]
    private let calendar = Calendar.current
    private let fileURL: URL

    private var pendingSaveWorkItem: DispatchWorkItem?

    init() {
        if let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dir = support.appendingPathComponent(AppConstants.applicationSupportSubdirectory, isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            } catch {
                workoutPersistenceLog.error("Application Support subdirectory failed to create: \(error.localizedDescription)")
            }
            fileURL = dir.appendingPathComponent(AppConstants.workoutsFileName)
        } else {
            workoutPersistenceLog.critical("Application Support URL unavailable — using app temp folder; data may not survive restarts.")
            let dir = FileManager.default.temporaryDirectory.appendingPathComponent(AppConstants.applicationSupportSubdirectory, isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            fileURL = dir.appendingPathComponent(AppConstants.workoutsFileName)
        }
        load()
    }

    deinit {
        pendingSaveWorkItem?.cancel()
        writeToDiskNow()
    }

    func logs(on date: Date) -> [WorkoutLog] {
        let start = calendar.startOfDay(for: date)
        return logsByDay[start] ?? []
    }

    func count(on date: Date) -> Int {
        logs(on: date).count
    }

    func add(day: Date, labelId: UUID, details: String = "") {
        let maxLen = AppConstants.maxWorkoutDetailLength
        let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
        let clamped = String(trimmed.prefix(maxLen))
        let log = WorkoutLog(id: UUID(), day: calendar.startOfDay(for: day), labelId: labelId, details: clamped)
        let key = calendar.startOfDay(for: log.day)
        logsByDay[key, default: []].append(log)
        scheduleSave()
    }

    func logCount(forLabelId id: UUID) -> Int {
        var n = 0
        for bucket in logsByDay.values {
            for log in bucket where log.labelId == id {
                n += 1
            }
        }
        return n
    }

    func reassignLabel(from: UUID, to: UUID) {
        guard from != to else { return }
        var changed = false
        for key in Array(logsByDay.keys) {
            guard var bucket = logsByDay[key] else { continue }
            var touched = false
            for i in bucket.indices where bucket[i].labelId == from {
                bucket[i].labelId = to
                touched = true
            }
            if touched {
                logsByDay[key] = bucket
                changed = true
            }
        }
        if changed { scheduleSave() }
    }

    func removeLogs(withLabelId id: UUID) {
        for key in Array(logsByDay.keys) {
            guard var bucket = logsByDay[key] else { continue }
            bucket.removeAll { $0.labelId == id }
            if bucket.isEmpty {
                logsByDay.removeValue(forKey: key)
            } else {
                logsByDay[key] = bucket
            }
        }
        scheduleSave()
    }

    func remove(id: UUID) {
        for key in Array(logsByDay.keys) {
            guard var bucket = logsByDay[key] else { continue }
            if let idx = bucket.firstIndex(where: { $0.id == id }) {
                bucket.remove(at: idx)
                if bucket.isEmpty {
                    logsByDay.removeValue(forKey: key)
                } else {
                    logsByDay[key] = bucket
                }
                scheduleSave()
                return
            }
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logsByDay = [:]
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([WorkoutLog].self, from: data)
            rebuildIndex(from: decoded)
        } catch {
            workoutPersistenceLog.error("Load failed (\(self.fileURL.lastPathComponent)): \(error.localizedDescription)")
            logsByDay = [:]
        }
    }

    private func rebuildIndex(from flat: [WorkoutLog]) {
        logsByDay.removeAll()
        for log in flat {
            let key = calendar.startOfDay(for: log.day)
            logsByDay[key, default: []].append(log)
        }
    }

    private func flattenedLogsForPersistence() -> [WorkoutLog] {
        var out: [WorkoutLog] = []
        for day in logsByDay.keys.sorted() {
            guard let bucket = logsByDay[day] else { continue }
            out.append(contentsOf: bucket)
        }
        return out
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

    /// Writes immediately (used after debounce coalescing and from `deinit`).
    private func writeToDiskNow() {
        let flat = flattenedLogsForPersistence()
        do {
            let data = try JSONEncoder().encode(flat)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            workoutPersistenceLog.error("Save failed (\(self.fileURL.lastPathComponent)): \(error.localizedDescription)")
        }
    }
}

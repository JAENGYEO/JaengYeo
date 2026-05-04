//
//  WidgetPresetEntityQuery.swift
//  JaengYeoWidgetExtension
//
//  Created by 손영빈 on 5/1/26.
//

import AppIntents

struct WidgetPresetEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [WidgetPresetAppEntity] {
        let presets = await MainActor.run {
            identifiers.compactMap { id in
                WidgetDataStore().fetchPreset(id: id)
            }
        }
        return presets.map {
            WidgetPresetAppEntity(id: $0.id, name: $0.name)
        }
    }

    func suggestedEntities() async throws -> [WidgetPresetAppEntity] {
        let presets = await MainActor.run {
            WidgetDataStore().fetchAllPresets()
        }
        return presets.map {
            WidgetPresetAppEntity(id: $0.id, name: $0.name)
        }
    }

    func defaultResult() async -> WidgetPresetAppEntity? {
        let preset = await MainActor.run {
            WidgetDataStore().fetchAllPresets().first
        }
        guard let preset else { return nil }
        return WidgetPresetAppEntity(id: preset.id, name: preset.name)
    }
}

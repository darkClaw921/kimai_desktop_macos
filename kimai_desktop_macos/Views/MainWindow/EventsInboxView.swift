import SwiftUI

struct EventsInboxView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedEventIds: Set<UUID> = []
    @State private var showProcessingSheet = false
    @State private var filterStatus: EventStatus? = .pending // nil = show all

    private var filteredEvents: [AgentEvent] {
        if let filterStatus {
            return appState.eventStore.events.filter { $0.status == filterStatus }
        }
        return appState.eventStore.events
    }

    var body: some View {
        Group {
            if filteredEvents.isEmpty {
                ContentUnavailableView(
                    "Нет событий",
                    systemImage: "bell.slash",
                    description: Text("События от агентов появятся здесь")
                )
            } else {
                List {
                    ForEach(filteredEvents) { event in
                        eventRow(event)
                    }
                }
            }
        }
        .navigationTitle("События")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Picker("Фильтр", selection: $filterStatus) {
                    Text("Все").tag(nil as EventStatus?)
                    Text("Ожидающие").tag(EventStatus.pending as EventStatus?)
                    Text("Обработанные").tag(EventStatus.processed as EventStatus?)
                    Text("Отклонённые").tag(EventStatus.dismissed as EventStatus?)
                }
                .pickerStyle(.segmented)
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    showProcessingSheet = true
                } label: {
                    Label("Обработать", systemImage: "arrow.right.circle")
                }
                .disabled(selectedEventIds.isEmpty)
                .help("Обработать выбранные события")
            }
        }
        .sheet(isPresented: $showProcessingSheet) {
            EventProcessingSheet(
                selectedEventIds: selectedEventIds,
                isPresented: $showProcessingSheet
            )
        }
        .onChange(of: filterStatus) { _, _ in
            // Clear selection when filter changes to avoid stale references
            selectedEventIds.removeAll()
        }
    }

    @ViewBuilder
    private func eventRow(_ event: AgentEvent) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if event.status == .pending {
                Toggle(isOn: Binding(
                    get: { selectedEventIds.contains(event.id) },
                    set: { isSelected in
                        if isSelected {
                            selectedEventIds.insert(event.id)
                        } else {
                            selectedEventIds.remove(event.id)
                        }
                    }
                )) {
                    EmptyView()
                }
                .toggleStyle(.checkbox)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.description)
                    .font(.headline)
                    .foregroundStyle(event.status == .dismissed ? .secondary : .primary)

                HStack(spacing: 8) {
                    Text(event.source)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(DateFormatting.formatShortDate(event.timestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Text("Реальное: \(DateFormatting.formatDuration(event.realDuration))")
                        .font(.caption)
                        .monospacedDigit()

                    Text("Расчётное: \(DateFormatting.formatDuration(event.estimatedHumanDuration))")
                        .font(.caption)
                        .monospacedDigit()
                }
            }

            Spacer()

            // Status indicator
            if event.status == .processed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }

            if event.status == .pending {
                Button {
                    appState.eventStore.dismiss(event.id)
                    selectedEventIds.remove(event.id)
                } label: {
                    Image(systemName: "xmark.circle")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Отклонить событие")
            }
        }
        .padding(.vertical, 2)
    }
}

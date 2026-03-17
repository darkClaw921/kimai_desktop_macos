import SwiftUI

struct EventProcessingSheet: View {
    @Environment(AppState.self) private var appState
    let selectedEventIds: Set<UUID>
    @Binding var isPresented: Bool

    @State private var selectedProject: KimaiProject?
    @State private var selectedActivity: KimaiActivity?
    @State private var useEstimatedDuration = true
    @State private var isProcessing = false
    @State private var resultMessage: String?

    /// Projects grouped by customer, sorted newest first (pattern from QuickStartView)
    private var groupedProjects: [(customerName: String, customerId: Int, projects: [KimaiProject])] {
        let grouped = Dictionary(grouping: appState.projects) { $0.customer }
        return grouped.map { customerId, projects in
            let customerName = projects.first?.customerName ?? "Без клиента"
            let sortedProjects = projects.sorted { $0.id > $1.id }
            return (customerName: customerName, customerId: customerId, projects: sortedProjects)
        }
        .sorted { $0.customerId > $1.customerId }
    }

    private var selectedEvents: [AgentEvent] {
        appState.eventStore.events.filter { selectedEventIds.contains($0.id) }
    }

    private var totalDuration: Int {
        selectedEvents.reduce(0) { sum, event in
            sum + (useEstimatedDuration ? event.estimatedHumanDuration : event.realDuration)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Создание записей времени")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Выбрано событий: \(selectedEventIds.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Form {
                Picker("Проект", selection: $selectedProject) {
                    Text("Выберите проект...").tag(nil as KimaiProject?)
                    ForEach(groupedProjects, id: \.customerId) { group in
                        Section(group.customerName) {
                            ForEach(group.projects) { project in
                                Text(project.name).tag(project as KimaiProject?)
                            }
                        }
                    }
                }
                .onChange(of: selectedProject) { _, newValue in
                    selectedActivity = nil
                    if let newValue {
                        Task { await appState.loadActivities(for: newValue) }
                    }
                }

                Picker("Активность", selection: $selectedActivity) {
                    Text("Выберите активность...").tag(nil as KimaiActivity?)
                    ForEach(appState.activities) { activity in
                        Text(activity.name).tag(activity as KimaiActivity?)
                    }
                }
                .disabled(selectedProject == nil)

                Picker("Тип времени", selection: $useEstimatedDuration) {
                    Text("Расчётное время").tag(true)
                    Text("Реальное время").tag(false)
                }
                .pickerStyle(.segmented)

                LabeledContent("Суммарная длительность") {
                    Text(DateFormatting.formatDuration(totalDuration))
                        .monospacedDigit()
                        .fontWeight(.medium)
                }
            }
            .formStyle(.grouped)

            if let resultMessage {
                Text(resultMessage)
                    .font(.callout)
                    .foregroundStyle(resultMessage.hasPrefix("Ошибка") ? .red : .green)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            HStack {
                Button("Отмена") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button {
                    processSelectedEvents()
                } label: {
                    if isProcessing {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal, 8)
                    } else {
                        Text("Создать записи")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(selectedProject == nil || selectedActivity == nil || isProcessing)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 420)
    }

    private func processSelectedEvents() {
        Task {
            isProcessing = true
            defer { isProcessing = false }
            do {
                let count = try await appState.processEvents(
                    eventIds: Array(selectedEventIds),
                    project: selectedProject!,
                    activity: selectedActivity!,
                    useEstimatedDuration: useEstimatedDuration
                )
                resultMessage = "Создано записей: \(count)"
                try? await Task.sleep(for: .seconds(1.5))
                isPresented = false
            } catch {
                resultMessage = "Ошибка: \(error.localizedDescription)"
            }
        }
    }
}

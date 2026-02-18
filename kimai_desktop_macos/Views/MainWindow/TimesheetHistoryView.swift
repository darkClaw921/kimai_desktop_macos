import SwiftUI

struct TimesheetHistoryView: View {
    @Environment(AppState.self) private var appState
    @State private var timesheetVM = TimesheetViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Filters
            filterBar

            Divider()

            // Table
            let filtered = timesheetVM.filteredTimesheets(
                from: appState.allTimesheets,
                projects: appState.projects,
                activities: appState.allActivities
            )

            if filtered.isEmpty {
                ContentUnavailableView(
                    "Нет записей",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Нет записей, соответствующих фильтрам.")
                )
            } else {
                Table(filtered) {
                    TableColumn("Проект") { timesheet in
                        Text(appState.resolvedProjectName(for: timesheet))
                    }
                    .width(min: 100, ideal: 150)

                    TableColumn("Активность") { timesheet in
                        Text(appState.resolvedActivityName(for: timesheet))
                    }
                    .width(min: 80, ideal: 120)

                    TableColumn("Описание") { timesheet in
                        Text(timesheet.description ?? "—")
                            .foregroundStyle(timesheet.description == nil ? .tertiary : .primary)
                    }
                    .width(min: 100, ideal: 200)

                    TableColumn("Дата") { timesheet in
                        if let date = timesheet.beginDate {
                            Text(DateFormatting.formatShortDate(date))
                        }
                    }
                    .width(min: 80, ideal: 120)

                    TableColumn("Длительность") { timesheet in
                        Text(timesheet.formattedDuration)
                            .font(.system(.body, design: .monospaced))
                    }
                    .width(min: 60, ideal: 80)

                    TableColumn("") { timesheet in
                        if !timesheet.isActive {
                            Button {
                                Task { await appState.restartTimesheet(timesheet) }
                            } label: {
                                Image(systemName: "play.circle")
                            }
                            .buttonStyle(.plain)
                            .help("Перезапустить")
                        }
                    }
                    .width(30)
                }
            }

            // Load more
            if appState.hasMoreHistory {
                Button("Загрузить ещё") {
                    Task { await appState.loadHistory() }
                }
                .padding(8)
            }
        }
        .navigationTitle("История")
        .task {
            await appState.loadProjects()
            await appState.loadHistory(reset: true)
        }
    }

    private var filterBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Поиск...", text: $timesheetVM.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(6)
            .background(.quaternary, in: .rect(cornerRadius: 8))

            Picker("Проект", selection: $timesheetVM.filterProject) {
                Text("Все проекты").tag(nil as KimaiProject?)
                ForEach(appState.projects) { project in
                    Text(project.name).tag(project as KimaiProject?)
                }
            }
            .frame(width: 150)

            DatePicker("С", selection: Binding(
                get: { timesheetVM.filterDateFrom ?? Date.distantPast },
                set: { timesheetVM.filterDateFrom = $0 }
            ), displayedComponents: .date)
            .labelsHidden()

            DatePicker("По", selection: Binding(
                get: { timesheetVM.filterDateTo ?? Date.now },
                set: { timesheetVM.filterDateTo = $0 }
            ), displayedComponents: .date)
            .labelsHidden()

            Button("Сбросить") {
                timesheetVM.filterProject = nil
                timesheetVM.filterDateFrom = nil
                timesheetVM.filterDateTo = nil
                timesheetVM.searchText = ""
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
        }
        .padding(12)
    }
}

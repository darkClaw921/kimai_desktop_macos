import SwiftUI

struct ProjectDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var projectsVM = ProjectsViewModel()
    @State private var expandedCustomers: Set<String> = []
    @State private var expandedProjects: Set<Int> = []
    @AppStorage("currencySuffix") private var currencySuffix = Constants.Defaults.currencySuffix

    var body: some View {
        List {
            if appState.projects.isEmpty {
                ContentUnavailableView(
                    "Нет проектов",
                    systemImage: "folder",
                    description: Text("Подключитесь к серверу Kimai, чтобы увидеть проекты.")
                )
            } else {
                let groups = projectsVM.groupedByCustomer(from: appState.projects)
                ForEach(groups) { group in
                    customerSection(group)
                }
            }
        }
        .searchable(text: $projectsVM.searchText, prompt: "Поиск проектов...")
        .navigationTitle("Проекты")
        .task {
            await appState.loadProjects()
            await appState.loadAllActivities()
            await appState.loadHistory(reset: true)
        }
    }

    // MARK: - Customer Level

    private func customerSection(_ group: CustomerGroup) -> some View {
        DisclosureGroup(isExpanded: customerBinding(group.id)) {
            ForEach(group.projects) { project in
                projectSection(project)
            }
        } label: {
            HStack {
                Image(systemName: "building.2")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(group.name)
                    .font(.title3.weight(.semibold))
                Spacer()
                let total = projectsVM.customerTotalDuration(
                    projects: group.projects,
                    from: appState.allTimesheets
                )
                let earnings = projectsVM.customerTotalEarnings(
                    projects: group.projects,
                    from: appState.allTimesheets
                )
                VStack(alignment: .trailing, spacing: 2) {
                    if total > 0 {
                        Text(DateFormatting.formatDuration(total))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    if earnings > 0 {
                        Text(formatEarnings(earnings))
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .onTapGesture { toggleCustomer(group.id) }
        }
    }

    // MARK: - Project Level

    private func projectSection(_ project: KimaiProject) -> some View {
        DisclosureGroup(isExpanded: projectBinding(project.id)) {
            let timesheets = projectsVM.projectTimesheets(
                projectId: project.id,
                from: appState.allTimesheets
            )
            if timesheets.isEmpty {
                Text("Нет записей")
                    .font(.body)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(timesheets) { timesheet in
                    timesheetRow(timesheet)
                }
            }
        } label: {
            HStack {
                if let color = project.color {
                    Circle()
                        .fill(Color(hex: color))
                        .frame(width: 12, height: 12)
                }
                Text(project.name)
                    .font(.headline)

                Spacer()

                let total = projectsVM.projectTotalDuration(
                    projectId: project.id,
                    from: appState.allTimesheets
                )
                let earnings = projectsVM.projectTotalEarnings(
                    projectId: project.id,
                    from: appState.allTimesheets
                )
                VStack(alignment: .trailing, spacing: 2) {
                    if total > 0 {
                        Text(DateFormatting.formatDuration(total))
                            .font(.system(.callout, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    if earnings > 0 {
                        Text(formatEarnings(earnings))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.green)
                    }
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .onTapGesture { toggleProject(project.id) }
        }
    }

    // MARK: - Timesheet Row

    private func timesheetRow(_ timesheet: KimaiTimesheet) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(appState.resolvedActivityName(for: timesheet))
                    .font(.body)
                    .lineLimit(1)
                if let desc = timesheet.description, !desc.isEmpty {
                    Text(desc)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(timesheet.formattedDuration)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(timesheet.isActive ? .green : .primary)

                if let rate = timesheet.rate, rate > 0 {
                    Text(formatEarnings(rate))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.green)
                }

                if let beginDate = timesheet.beginDate {
                    Text(DateFormatting.formatShortDate(beginDate))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            if !timesheet.isActive {
                Button {
                    appState.requestRestart(timesheet)
                } label: {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
                .help("Перезапустить таймер")
            }
        }
        .padding(.vertical, 3)
    }

    // MARK: - Helpers

    private static let earningsFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.groupingSeparator = " "
        f.groupingSize = 3
        f.usesGroupingSeparator = true
        return f
    }()

    private func formatEarnings(_ amount: Double) -> String {
        let number = Self.earningsFormatter.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount)
        return "\(number) \(currencySuffix)"
    }

    private func toggleCustomer(_ id: String) {
        if expandedCustomers.contains(id) {
            expandedCustomers.remove(id)
        } else {
            expandedCustomers.insert(id)
        }
    }

    private func toggleProject(_ id: Int) {
        if expandedProjects.contains(id) {
            expandedProjects.remove(id)
        } else {
            expandedProjects.insert(id)
        }
    }

    // MARK: - Bindings

    private func customerBinding(_ id: String) -> Binding<Bool> {
        Binding(
            get: { expandedCustomers.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    expandedCustomers.insert(id)
                } else {
                    expandedCustomers.remove(id)
                }
            }
        )
    }

    private func projectBinding(_ id: Int) -> Binding<Bool> {
        Binding(
            get: { expandedProjects.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    expandedProjects.insert(id)
                } else {
                    expandedProjects.remove(id)
                }
            }
        )
    }
}

// MARK: - Color from hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        if hex.count == 6 {
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        } else {
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}

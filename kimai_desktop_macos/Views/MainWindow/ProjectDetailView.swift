import SwiftUI

struct ProjectDetailView: View {
    @Environment(AppState.self) private var appState
    @State private var projectsVM = ProjectsViewModel()

    var body: some View {
        List {
            if appState.projects.isEmpty {
                ContentUnavailableView(
                    "Нет проектов",
                    systemImage: "folder",
                    description: Text("Подключитесь к серверу Kimai, чтобы увидеть проекты.")
                )
            } else {
                let filtered = projectsVM.filteredProjects(from: appState.projects)
                ForEach(filtered) { project in
                    projectRow(project)
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

    private func projectRow(_ project: KimaiProject) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let color = project.color {
                    Circle()
                        .fill(Color(hex: color))
                        .frame(width: 10, height: 10)
                }

                Text(project.name)
                    .font(.headline)

                if !project.customerName.isEmpty {
                    Text("(\(project.customerName))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                let total = projectsVM.projectTotalDuration(
                    projectId: project.id,
                    from: appState.allTimesheets
                )
                Text(DateFormatting.formatDuration(total))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            // Activities for this project
            let activities = appState.allActivities.filter { $0.project == project.id }
            if !activities.isEmpty {
                HStack(spacing: 8) {
                    ForEach(activities) { activity in
                        Text(activity.name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: .capsule)
                    }
                }
            }
        }
        .padding(.vertical, 4)
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

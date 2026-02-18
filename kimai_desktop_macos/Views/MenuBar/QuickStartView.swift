import SwiftUI

struct QuickStartView: View {
    @Environment(AppState.self) private var appState

    @State private var selectedProject: KimaiProject?
    @State private var selectedActivity: KimaiActivity?
    @State private var description: String = ""

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Быстрый запуск")
                    .font(.headline)

                Picker("Проект", selection: $selectedProject) {
                    Text("Выберите проект...").tag(nil as KimaiProject?)
                    ForEach(appState.projects) { project in
                        Text(project.displayName).tag(project as KimaiProject?)
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

                TextField("Описание (необязательно)", text: $description)
                    .textFieldStyle(.roundedBorder)

                Button {
                    guard let project = selectedProject, let activity = selectedActivity else { return }
                    Task {
                        await appState.startTimer(
                            project: project,
                            activity: activity,
                            description: description.isEmpty ? nil : description
                        )
                        description = ""
                    }
                } label: {
                    Label("Запустить таймер", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .glassEffect(.regular.interactive(), in: .capsule)
                .disabled(selectedProject == nil || selectedActivity == nil || appState.isLoading)
            }
        }
    }
}

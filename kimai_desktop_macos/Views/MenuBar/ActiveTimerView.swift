import SwiftUI

struct ActiveTimerView: View {
    @Environment(AppState.self) private var appState

    let timesheet: KimaiTimesheet

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(appState.resolvedProjectName(for: timesheet))
                            .font(.headline)
                            .lineLimit(1)
                        Text(appState.resolvedActivityName(for: timesheet))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    StatusIndicator(status: .tracking)
                }

                HStack {
                    ElapsedTimeText(timerService: appState.timerService)

                    Spacer()

                    Button {
                        Task { await appState.stopTimer() }
                    } label: {
                        Label("Стоп", systemImage: "stop.fill")
                            .font(.body.weight(.medium))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .glassEffect(.regular.interactive(), in: .capsule)
                }
            }
        }
    }
}

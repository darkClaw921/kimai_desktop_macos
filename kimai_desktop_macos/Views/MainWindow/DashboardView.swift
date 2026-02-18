import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var timesheetVM = TimesheetViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Active timer section
                activeTimerSection

                // Today summary
                todaySummarySection

                // Week summary
                weekSummarySection
            }
            .padding(20)
        }
        .navigationTitle("Обзор")
        .task {
            await appState.loadHistory(reset: true)
        }
    }

    @ViewBuilder
    private var activeTimerSection: some View {
        if let activeTimesheet = appState.activeTimesheet {
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Активный таймер")
                            .font(.headline)
                        Spacer()
                        StatusIndicator(status: .tracking)
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.resolvedProjectName(for: activeTimesheet))
                                .font(.title3.weight(.medium))
                            Text(appState.resolvedActivityName(for: activeTimesheet))
                                .foregroundStyle(.secondary)
                            if let desc = activeTimesheet.description, !desc.isEmpty {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 8) {
                            ElapsedTimeText(
                                timerService: appState.timerService,
                                font: .system(.title, design: .monospaced)
                            )

                            Button {
                                Task { await appState.stopTimer() }
                            } label: {
                                Label("Стоп", systemImage: "stop.fill")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                        }
                    }
                }
            }
        } else {
            GlassCard {
                HStack {
                    Image(systemName: "clock")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Нет активного таймера")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var todaySummarySection: some View {
        let todayEntries = timesheetVM.todayTimesheets(from: appState.allTimesheets)
        let totalDuration = timesheetVM.totalDuration(of: todayEntries)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Сегодня")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text(DateFormatting.formatDuration(totalDuration))
                    .font(.system(.title3, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if todayEntries.isEmpty {
                Text("Нет записей за сегодня")
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(todayEntries) { timesheet in
                    TimesheetRow(timesheet: timesheet) {
                        Task { await appState.restartTimesheet(timesheet) }
                    }
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private var weekSummarySection: some View {
        let weekEntries = timesheetVM.weekTimesheets(from: appState.allTimesheets)
        let totalDuration = timesheetVM.totalDuration(of: weekEntries)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Эта неделя")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text(DateFormatting.formatDuration(totalDuration))
                    .font(.system(.title3, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            // Group by project
            let grouped = Dictionary(grouping: weekEntries) { $0.projectId }
            ForEach(Array(grouped.keys.sorted()), id: \.self) { projectId in
                if let entries = grouped[projectId], let first = entries.first {
                    HStack {
                        Text(appState.resolvedProjectName(for: first))
                            .font(.subheadline)
                        Spacer()
                        Text(DateFormatting.formatDuration(
                            entries.compactMap(\.duration).reduce(0, +)
                        ))
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

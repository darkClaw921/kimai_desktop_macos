import SwiftUI

struct StatusIndicator: View {
    enum Status {
        case online
        case offline
        case tracking

        var color: Color {
            switch self {
            case .online: .green
            case .offline: .red
            case .tracking: .orange
            }
        }

        var label: String {
            switch self {
            case .online: "Подключено"
            case .offline: "Отключено"
            case .tracking: "Отслеживание"
            }
        }
    }

    let status: Status

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
                .shadow(color: status.color.opacity(0.5), radius: 3)

            Text(status.label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

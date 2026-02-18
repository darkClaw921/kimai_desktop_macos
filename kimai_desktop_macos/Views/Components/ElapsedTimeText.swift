import SwiftUI

struct ElapsedTimeText: View {
    let timerService: TimerService
    var font: Font = .system(.title2, design: .monospaced)

    var body: some View {
        Text(timerService.formattedElapsed)
            .font(font)
            .contentTransition(.numericText())
            .animation(.linear(duration: 0.3), value: timerService.elapsed)
    }
}

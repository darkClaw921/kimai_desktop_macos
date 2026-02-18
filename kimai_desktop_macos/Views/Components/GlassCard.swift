import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            content
                .padding(12)
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
        } else {
            content
                .padding(12)
                .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
        }
        #else
        content
            .padding(12)
            .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
        #endif
    }
}

extension View {
    @ViewBuilder
    func interactiveGlassEffect() -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: .capsule)
        } else {
            self
        }
        #else
        self
        #endif
    }
}

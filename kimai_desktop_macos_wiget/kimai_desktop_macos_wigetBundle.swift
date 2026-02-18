import WidgetKit
import SwiftUI

@main
struct kimai_desktop_macos_wigetBundle: WidgetBundle {
    var body: some Widget {
        KimaiTrackingWidget()
        kimai_desktop_macos_wigetControl()
    }
}

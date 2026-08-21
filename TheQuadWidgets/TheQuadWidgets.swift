import WidgetKit
import SwiftUI

@main
struct TheQuadWidgets: WidgetBundle {
    var body: some Widget {
        ScheduleWidget()
        DayBadgeWidget()
        WorkWidget()
    }
}

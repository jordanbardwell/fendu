import WidgetKit
import SwiftUI

struct FenduWidget: Widget {
    let kind = "FenduWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FenduTimelineProvider()) { entry in
            FenduWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Fendu Budget")
        .description("See your remaining paycheck balance at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

//
//  BillsWidget.swift
//  BillsWidget
//

import SwiftUI
import WidgetKit

@main
struct BillsWidgets: WidgetBundle {
    var body: some Widget {
        BillsLiveScoreWidget()
    }
}

struct BillsLiveScoreWidget: Widget {
    let kind = "BillsLiveScore"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ScoreTimelineProvider()) { entry in
            BillsLiveScoreWidgetView(entry: entry)
        }
        .configurationDisplayName("Bills Live Score")
        .description("Live score, clock, possession and game details for the Buffalo Bills.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

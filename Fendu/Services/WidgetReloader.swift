import WidgetKit

enum WidgetReloader {
    static func reloadAll() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

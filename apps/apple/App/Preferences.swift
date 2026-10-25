import Foundation

enum Preferences {
    static let showsMenuBarExtraKey = "showsMenuBarExtra"

    static var showsMenuBarExtra: Bool {
        UserDefaults.standard.object(forKey: showsMenuBarExtraKey) as? Bool ?? true
    }
}

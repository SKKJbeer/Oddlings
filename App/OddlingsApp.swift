import SwiftUI

@main
struct OddlingsApp: App {
    init() {
        AppFonts.register()
    }

    var body: some Scene {
        WindowGroup {
            StartView()
        }
    }
}


import SwiftUI

@main
struct LeafApp: App {
    
    var body: some Scene {
        MenuBarExtra {
            MenuView()
        } label: {
            Label("Leaf", systemImage: "leaf.fill")
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
        }
    }
}

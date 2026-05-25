import SwiftUI
import Sparkle

@main
struct LeafApp: App {
    
    @AppStorage("isFirstLaunch") var isFirstLaunch: Bool = true
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
 
    @SceneBuilder
    var body: some Scene {
        MenuBarExtra {
            if !isFirstLaunch {
                MenuView(tracker: appDelegate.tracker)
            } else {
                Button {
                    AppDelegate.showOnboarding()
                } label: {
                    Text("Complete Setup ...")
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                }
                .buttonStyle(.bordered)
            }
        } label: {
            Label("Leaf", systemImage: "leaf.fill")
        }
        .menuBarExtraStyle(.window)
        .onChange(of: isFirstLaunch) { oldValue, newValue in
            if newValue == false {
                appDelegate.tracker.start()
            }
        }
        
        Settings {
            SettingsView(updater: updaterController.updater)
        }
    }
}

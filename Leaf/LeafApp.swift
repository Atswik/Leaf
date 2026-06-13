import SwiftUI
import Sparkle

@main
struct LeafApp: App {
    
    @AppStorage("isFirstLaunch") var isFirstLaunch: Bool = true
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    enum HoverOver: Hashable {
        case setup
        case quit
    }
    
    @State private var hoveredButton: HoverOver? = nil
 
    @SceneBuilder
    var body: some Scene {
        MenuBarExtra {
            if !isFirstLaunch {
                MenuView(tracker: appDelegate.tracker)
            } else {
                VStack(spacing: 0) {
                    Button {
                        AppDelegate.showOnboarding()
                    } label: {
                        Text("Complete Setup...")
                            .frame(maxWidth: 150, alignment: .leading)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4.5)
                            .foregroundStyle(hoveredButton == .setup ? Color.white : Color.primary)
                            .background(
                                Group {
                                    if hoveredButton == .setup {
                                        RoundedRectangle(cornerRadius: 11)
                                            .fill(Color.blue.opacity(0.8))
                                    } else {
                                        RoundedRectangle(cornerRadius: 11)
                                            .fill(Color.clear)
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        hoveredButton = hovering ? .setup : nil
                    }
                    
                    Button {
                        NSApplication.shared.terminate(self)
                    } label : {
                        Text("Quit app")
                            .frame(maxWidth: 150, alignment: .leading)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4.5)
                            .foregroundStyle(hoveredButton == .quit ? Color.white : Color.primary)
                            .background(
                                Group {
                                    if hoveredButton == .quit {
                                        RoundedRectangle(cornerRadius: 11)
                                            .fill(Color.blue.opacity(0.8))
                                    } else {
                                        RoundedRectangle(cornerRadius: 11)
                                            .fill(Color.clear)
                                    }
                                }
                            )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        hoveredButton = hovering ? .quit : nil
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 4)
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
            SettingsView(updater: appDelegate.updater)
        }
    }
}

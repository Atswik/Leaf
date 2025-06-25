
import SwiftUI

struct MenuView: View {
    
    var tracker: Tracker = Tracker()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading) {
                if tracker.runningApps.count > 0 {
                    ForEach(Array(tracker.runningApps), id: \.key) { app in
                        AppView(app: app, tracker: tracker, notifyOrNot: tracker.nonNotifyApps[app.key.bundleIdentifier ?? ""] ?? true)
                    }
                } else {
                    HStack {
                        Image(systemName: "leaf.fill")
                            .imageScale(.large)
                            .foregroundStyle(.green)
                        VStack {
                            Text("No apps to track")
                        }
                    }
                }
            }
            .padding(5)
            
            Divider()
            
            ButtonsView()
                .padding(.bottom, 1.5)
        }
        .frame(width: 230)
        .padding(5)
        .onAppear {
            tracker.refreshApps()
        }
    }
}

struct AppView: View {
    
    var app: (key: NSRunningApplication, value: TimeInterval)
    var tracker: Tracker
    var notifyOrNot: Bool
    
    @Environment(\.colorScheme) var colorScheme

    @State private var hoveringApp: String? = nil
    
    var body: some View {
        HStack(alignment: .center) {
            
            if let icon = app.key.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 26, height: 26)
                    .opacity(notifyOrNot ? 0.6 : 1.0)
            }
            
            Text(app.key.localizedName ?? "Unknown")
                .foregroundStyle(notifyOrNot ? Color.primary.opacity(0.5) : .primary)
                
            Spacer()
            
            if app.key.bundleIdentifier == hoveringApp || notifyOrNot {
                Button {
                    tracker.toggleNotifications(app: app.key.bundleIdentifier ?? "")
                } label: {
                    Image(systemName: notifyOrNot ? "bell.slash.fill" : "bell")
                        .frame(height: 15)
                        .foregroundStyle(Color.primary.opacity(0.75))
                }
                .buttonStyle(.plain)
            }
        }
        .onHover { hovering in
            hoveringApp = hovering ? app.key.bundleIdentifier : nil
        }
    }
}

struct ButtonsView: View {
    
    enum HoverOver: Hashable {
        case settings
        case quit
    }

    @State private var hoveredButton: HoverOver? = nil
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 1) {
            
            // Settings button
            Group {
                Button {
                    openSettings()
                } label: {
                    Text("Settings")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4.5)
                        .foregroundStyle(hoveredButton == .settings ? Color.white : Color.primary)
                        .background(
                            Group {
                                if hoveredButton == .settings {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue.opacity(0.7))
                                } else {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.clear)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    hoveredButton = hovering ? .settings : nil
                }
            }
            
            // Quit button
            Group {
                Button {
                    NSApplication.shared.terminate(self)
                } label: {
                    Text("Quit")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4.5)
                        .foregroundStyle(hoveredButton == .quit ? Color.white : Color.primary)
                        .background(
                            Group {
                                if hoveredButton == .quit {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.blue.opacity(0.7))
                                } else {
                                    RoundedRectangle(cornerRadius: 4)
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
        }
    }
    
    func openSettings() {
        let environment = EnvironmentValues()
        environment.openSettings()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
    }
}

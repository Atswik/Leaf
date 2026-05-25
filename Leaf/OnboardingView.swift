//
//  OnboardingView-Alt.swift
//  Leaf
//
//  Created by Satwik on 4/19/26.
//

import SwiftUI
import UserNotifications

struct OnboardingView: View {
    var tracker: Tracker
    @Binding var isFirstLaunch: Bool
    @State private var hasRequested = false
    
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: HEADER SECTION
            VStack(spacing: 10) {
                Image(systemName: "leaf.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color.green.gradient)
                            
                Text("Setup Leaf")
                    .font(.title)
                    .fontWeight(.medium)
            }

            // MARK: Step 1: Request Permission
            if !hasRequested {
                
                Text("Allow Notification to receive alerts\n about inactive apps.")
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button {
                    tracker.requestNotificationPermission { granted in
                        hasRequested = true
                    }
                } label: {
                    Text("1. Allow Notifications")
                        .frame(maxWidth: 200)
                        .padding(.vertical, 5)
                }
                .applyOnboardingStyle()
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                
            } else {
                // MARK: Step 2: Open Notification Settings
                
                Text(getInstructionText())
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                
                VStack(spacing: 15) {
                    Button {
                        let bundleID = Bundle.main.bundleIdentifier ?? ""
                        let urlString = "x-apple.systempreferences:com.apple.preference.notifications?id=\(bundleID)"
                        
                        if let url = URL(string: urlString) {
                            NSWorkspace.shared.open(url)
                            completeOnboarding()
                        }
                    } label: {
                        Text("2. Open Notification Settings")
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                    }
                    .applyOnboardingStyle()
                    .buttonBorderShape(.capsule)
                    
                    HStack(spacing: 16) {
                        Button("Skip") {
                            completeOnboarding()
                        }
                        .buttonStyle(.borderless)
                        .opacity(0.7)
                    }
                    .padding(.top, 5)
                }
            }
            
        }
        .padding(30)
        .frame(width: 450, height: 350)
    }
    
    private func getInstructionText() -> String {
        if #available(macOS 26.0, *) {
            return "For persistent alerts, please change \n Leaf's Alert style to Persistent in Settings."
        } else {
            return "For persistent alerts, please change \n Leaf's notification style to Alerts in Settings."
        }
    }
    
    private func completeOnboarding() {
        isFirstLaunch = false
        NSApp.keyWindow?.close()
        sendWelcomeNotification()
    }
    
    private func sendWelcomeNotification() {
        
        let okAction = UNNotificationAction(
            identifier: "dismiss",
            title: "OK",
            options: [.destructive]
        )
        let category = UNNotificationCategory(
            identifier: "welcome",
            actions: [okAction],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        let content = UNMutableNotificationContent()
        content.title = "You're all set!"
        content.body = "Leaf will notify you when apps have been inactive for too long."
        content.sound = .default
        content.categoryIdentifier = "welcome"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "welcome", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}

#Preview {
    OnboardingView(tracker: Tracker(), isFirstLaunch: .constant(true))
}

extension View {
    @ViewBuilder
    func applyOnboardingStyle() -> some View {
        if #available(macOS 26.0, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
    }
}

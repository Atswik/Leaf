//
//  SparkleDelegate.swift
//  Leaf
//
//  Created by Satwik on 6/9/26.
//


import Sparkle
import UserNotifications

class SparkleDelegate: NSObject, SPUStandardUserDriverDelegate {
    
    var supportsGentleScheduledUpdateReminders: Bool {
        return true
    }
    
    // MARK: HANDLING OF UPDATES
    /// I decided to go with the Sparkle's textbook implementation to handle showing the update
    /// For more information, see https://sparkle-project.org/documentation/gentle-reminders/
    
//    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
//        return false
//    }
    
    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        
        if !handleShowingUpdate || state.userInitiated {
            return
        }
        
        // 1. Create your gentle reminder (A native Notification!)
        let content = UNMutableNotificationContent()
        content.title = "Leaf Update Available 🌵"
        content.body = "Version \(update.displayVersionString) is ready to install."
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: "LEAF_UPDATE", content: content, trigger: nil)
        
        // 2. Fire the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send update notification: \(error)")
            }
        }
    }
    
    func standardUserDriverWillFinishUpdateSession() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["LEAF_UPDATE"])
    }
}

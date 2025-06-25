
import UserNotifications
import SwiftUI

@Observable class Tracker: NSObject, UNUserNotificationCenterDelegate {
    
    var runningApps: [NSRunningApplication : TimeInterval] = [:]
    
    var nonNotifyApps: [String : Bool] = [:]
    
    @AppStorage("closingTime") @ObservationIgnored private var closingTime: Int = 10
    @AppStorage("quitWithoutNotify") @ObservationIgnored private var quitWithoutNotify: Bool = false
    @AppStorage("goingToSleep") @ObservationIgnored private var goingToSleep: Bool = false
    
    @ObservationIgnored private var sleepStartTime: Date = Date()
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var notifiedApps = Set<String>()
    
    override init() {
        super.init()
        
        if !UserDefaults.standard.bool(forKey: "hasNotificationAccess") {
            requestNotificationPermission()
        }
        
        UNUserNotificationCenter.current().delegate = self
        
        initializeRunningApps()
        receiveAppUpdates()
        
        self.timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.refreshApps()
            }
        }
    }
    
    func quitApp(appID: Int32) {
        if let app = NSRunningApplication(processIdentifier: appID) {
            DispatchQueue.main.async {
                app.terminate()
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification Permission granted")
                UserDefaults.standard.set(true, forKey: "hasNotificationAccess")
            } else {
                print("Permission Denied")
                if let error = error {
                    print("\(error)")
                }
            }
        }
    }
    
    private func initializeRunningApps() {
        
        let apps = NSWorkspace.shared.runningApplications
        
        for app in apps {
            if !isExcludedApp(app: app) {
                DispatchQueue.main.async {
                    print("initializeRunningApps: Added \(app.localizedName!)")
                    self.runningApps[app] = ProcessInfo.processInfo.systemUptime
                    self.nonNotifyApps[app.bundleIdentifier ?? ""] = false
                }
            }
        }
    }
    
    private func updateActiveApp() {
        
        self.removeTerminatedApps()
        
        if let activeApp = NSWorkspace.shared.frontmostApplication, !isExcludedApp(app: activeApp) {
            DispatchQueue.main.async {
                print("[\(Date())] - updateActiveApp: Updated \(activeApp.localizedName!)")
                
                self.runningApps[activeApp] = ProcessInfo.processInfo.systemUptime
                self.notifiedApps.remove(activeApp.bundleIdentifier ?? "")
                
                if self.nonNotifyApps[activeApp.bundleIdentifier ?? ""] == nil {
                    self.nonNotifyApps[activeApp.bundleIdentifier ?? ""] = false
                }
            }
        }
    }
    
    internal func refreshApps() {
        removeTerminatedApps()
        trackAndTerminate()
    }
    
    private func addLaunchedApps() {
        let apps = NSWorkspace.shared.runningApplications
        
        for app in apps {
            if !isExcludedApp(app: app) && self.runningApps[app] == nil {
                DispatchQueue.main.async {
                    self.runningApps[app] = ProcessInfo.processInfo.systemUptime
                }
            }
        }
    }
        
    private func removeTerminatedApps() {
        let apps = NSWorkspace.shared.runningApplications
        
        let currentApps = apps.compactMap { $0 }
        DispatchQueue.main.async {
            self.runningApps = self.runningApps.filter { currentApps.contains($0.key) }
        }
        
        for app in runningApps.keys {
            if isExcludedApp(app: app) {
                runningApps[app] = nil
            }
        }
    }
    
    internal func toggleNotifications(app: String) {
        
        if nonNotifyApps[app] == false {
            DispatchQueue.main.async {
                self.nonNotifyApps[app] = true
            }
        }
        
        if nonNotifyApps[app] == true {
            DispatchQueue.main.async {
                self.nonNotifyApps[app] = false
            }
        }
    }
    
    private func trackAndTerminate() {
        let now = ProcessInfo.processInfo.systemUptime
        
        for (app, _) in runningApps {
            if app.isActive {
                self.runningApps[app] = now
            } else {
                // New efficient approach
                if let lastTime = self.runningApps[app], now - lastTime > TimeInterval(closingTime * 60) && !notifiedApps.contains(app.bundleIdentifier ?? "") && nonNotifyApps[app.bundleIdentifier ?? ""] != true {
                    if !quitWithoutNotify {
                        sendNotification(app: app)
                        notifiedApps.insert(app.bundleIdentifier ?? "shit-happens")
                    } else {
                        quitApp(appID: app.processIdentifier)
                    }
                } else {
                    print("[\(Date())] - Not quitting \(app.localizedName!) bcoz timeSinceIdle = \(now - self.runningApps[app]!) < closingTime")
                }
            }
        }
    }
    
    private func sendNotification(app: NSRunningApplication) {
        let content = UNMutableNotificationContent()
        content.title = "Want me to quit \(app.localizedName ?? "an unknown app")?"
        content.sound = .default
        content.userInfo = ["persistent" : true, "appID" : app.processIdentifier]
        content.categoryIdentifier = "QUIT_ALERT"
        
        let quitAction = UNNotificationAction(identifier: "QUIT_APP", title: "Quit")
        let category = UNNotificationCategory(
            identifier: "QUIT_ALERT",
            actions: [quitAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("\(error)")
            }
        }
    }
    
    private func isExcludedApp(app: NSRunningApplication) -> Bool {
        let currentApp = Bundle.main.bundleIdentifier
        
        let excludedApps = [
            "com.apple.dock",
            "com.apple.Siri",
            "com.apple.finder",
            "com.apple.coreautha",
            "com.apple.Spotlight",
            "com.apple.loginwindow",
            "com.timpler.screenstudio",
            "com.apple.systemuiserver",
            "com.apple.notificationcenterui",
        ]
        
        if app.activationPolicy == .regular && app.bundleIdentifier != currentApp && !excludedApps.contains(app.bundleIdentifier ?? "") {
            return false
        }
        return true
    }
    
    private func resetTimeStamps() {
        let apps = NSWorkspace.shared.runningApplications
        
        for app in apps {
            if !isExcludedApp(app: app) {
                DispatchQueue.main.async {
                    self.runningApps[app] = ProcessInfo.processInfo.systemUptime
                }
            }
        }
    }
    
    private func asleepAndAwake() {
        
        if (goingToSleep) {
            print("About to stop the timer - \(Date())")
            
            sleepStartTime = Date()
            timer?.invalidate()
            timer = nil
            
        } else {
            print("About to start the timer again - \(Date())")
            
            let currentTime = Date()
            print("Difference = \(currentTime.timeIntervalSince(sleepStartTime))")
            
            if currentTime.timeIntervalSince(sleepStartTime) > 30 {
                DispatchQueue.main.async {
                    self.resetTimeStamps()
                }
            }
            
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.trackAndTerminate()
                }
            }
        }
    }
    
    private func receiveAppUpdates() {
        
        let notificationCenter = NSWorkspace.shared.notificationCenter
         
        notificationCenter.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { _ in
            self.addLaunchedApps()
        }
        
        notificationCenter.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { _ in
            self.removeTerminatedApps()
        }
        
        notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { _ in
            self.updateActiveApp()
        }
        
        notificationCenter.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { _ in
            self.goingToSleep = true
            self.asleepAndAwake()
        }
        
        notificationCenter.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { _ in
            self.goingToSleep = false
            self.asleepAndAwake()
        }
    }
    
    internal func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.actionIdentifier == "QUIT_APP" {
            if let appID = response.notification.request.content.userInfo["appID"] as? Int32 {
                quitApp(appID: appID)
            }
        }
        
        completionHandler()
    }
}


import UserNotifications
import SwiftUI

@Observable class Tracker: NSObject, UNUserNotificationCenterDelegate {
    
    var runningApps: [NSRunningApplication : TimeInterval] = [:]
//    var currentMemoryMap: [Int32: Double] = [:]
    
    var nonNotifyApps: [String : Bool] = [:]
    
    @AppStorage("smartAlerts") @ObservationIgnored private var smartAlerts: Bool = true
    @AppStorage("closingTime") @ObservationIgnored private var closingTime: Int = 15
    @AppStorage("quitWithoutNotify") @ObservationIgnored private var quitWithoutNotify: Bool = false
    @AppStorage("goingToSleep") @ObservationIgnored private var goingToSleep: Bool = false
    
    @ObservationIgnored private let memoryThresholdMB: Double = 200.0
    @ObservationIgnored private var sleepStartTime: Date = Date()
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var notifiedApps = Set<String>()
    @ObservationIgnored private var isRunning = false
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        
        initializeRunningApps()
        receiveAppUpdates()
        startTimer()
    }
    
    private func startTimer() {
        self.timer?.invalidate() // Cleans up any old timer
        self.timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true, block: { [weak self] _ in
            guard let self else { return }
            
            DispatchQueue.main.async {
                self.refreshApps()
            }
        })
        
    }
 
    func quitApp(appID: Int32) {
        if let app = NSRunningApplication(processIdentifier: appID) {
            DispatchQueue.main.async {
                app.terminate()
            }
        }
    }
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UserDefaults.standard.set(true, forKey: "hasNotificationAccess")
                } else if let error = error {
                    print("Permission Error: \(error)")
                }
                
                completion(granted)
            }
            
        }
    }
    
    private func initializeRunningApps() {
        
        let apps = NSWorkspace.shared.runningApplications
        
        for app in apps {
            if !isExcludedApp(app: app) {
                DispatchQueue.main.async {
//                    print("initializeRunningApps: Added \(app.localizedName!)")
                    self.runningApps[app] = ProcessInfo.processInfo.systemUptime
                    let bundleID = app.bundleIdentifier ?? ""
                    if self.nonNotifyApps[bundleID] == nil {
                        // Silences media players by default
                        self.nonNotifyApps[bundleID] = self.isMediaPlayer(bundleID: bundleID)
                    }
                }
            }
        }
    }
    
    private func updateActiveApp() {
        
        self.removeTerminatedApps()
        
        if let activeApp = NSWorkspace.shared.frontmostApplication, !isExcludedApp(app: activeApp) {
            DispatchQueue.main.async {
//                print("[\(Date())] - updateActiveApp: Updated \(activeApp.localizedName!)")
                
                self.runningApps[activeApp] = ProcessInfo.processInfo.systemUptime
                
                let bundleID = activeApp.bundleIdentifier ?? ""
                self.notifiedApps.remove(bundleID)
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [bundleID])
                
                if self.nonNotifyApps[activeApp.bundleIdentifier ?? ""] == nil {
                    self.nonNotifyApps[bundleID] = self.isMediaPlayer(bundleID: bundleID)
                }
            }
        }
    }
    
    internal func refreshApps() {
        removeTerminatedApps()
        trackAndTerminate()
    }
    
    private func isMediaPlayer(bundleID: String?) -> Bool {
        guard let id = bundleID else { return false }
        let mediaPlayers = [
            "com.apple.Music",
            "com.spotify.client",
            "com.amazon.music",
            "com.coppertino.Vox",
            "app.ytmdesktop.ytmdesktop",
            "com.tidal.desktop",
            "org.videolan.vlc",
            "com.colliderli.iina",
            "com.apple.podcasts",
            "com.apple.TV",
            "com.apple.QuickTimePlayerX"
        ]
        return mediaPlayers.contains(id)
    }
    
    private func addLaunchedApps() {
        let apps = NSWorkspace.shared.runningApplications
        
        for app in apps {
            if !isExcludedApp(app: app) && self.runningApps[app] == nil {
                DispatchQueue.main.async {
                    self.runningApps[app] = ProcessInfo.processInfo.systemUptime
                    
                    let bundleID = app.bundleIdentifier ?? ""
                    if self.nonNotifyApps[bundleID] == nil {
                        self.nonNotifyApps[bundleID] = self.isMediaPlayer(bundleID: bundleID)
                    }
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
    
    private func getMemoryUsageMap() -> [Int32: Double] {
        let task = Process()
        let pipe = Pipe()
        
        task.executableURL = URL(filePath: "/bin/ps")
        task.arguments = ["-e", "-o", "pid=,rss="]
        task.standardOutput = pipe
        
        var memoryMap: [Int32: Double] = [:]
        
        do {
            try task.run()
            let data = try pipe.fileHandleForReading.readToEnd() ?? Data()
            
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                for line in lines {
                    let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                    if parts.count == 2, let pid = Int32(parts[0]), let rssKB = Double(parts[1]) {
                        
                        memoryMap[pid] = rssKB / 1024.0
                    }
                }
            }
        } catch {
            print("Leaf: Failed to fetch memory map - \(error)")
        }
        
        return memoryMap
    }
    
    private func trackAndTerminate() {
        let now = ProcessInfo.processInfo.systemUptime
        
        for (app, _) in runningApps {
            if app.isActive {
                self.runningApps[app] = now
            }
        }
        
        let currentMemoryMap = smartAlerts ? getMemoryUsageMap() : [:]
        
        var notificationGuys: [(app: NSRunningApplication, idleTime: TimeInterval)] = []
        
        for (app, lastTime) in runningApps {
            if !app.isActive {
                let idleTime = now - lastTime
                print("\(app.localizedName ?? "Unknown"): \(idleTime)")
                
                let appMemoryUsage = currentMemoryMap[app.processIdentifier] ?? 0.0
                let isMemoryConsuming = !smartAlerts || (appMemoryUsage >= memoryThresholdMB)
                
                if idleTime > TimeInterval(closingTime * 60) &&
                    !notifiedApps.contains(app.bundleIdentifier ?? "") &&
                    nonNotifyApps[app.bundleIdentifier ?? ""] != true && isMemoryConsuming {
                    
                    if quitWithoutNotify {
                        quitApp(appID: app.processIdentifier)
                    } else {
                        notificationGuys.append((app, idleTime))
                    }
                }
            }
        }
        
        // Rate-limiting notifications
        if !notificationGuys.isEmpty {
            let sortedGuys = notificationGuys.sorted { $0.idleTime > $1.idleTime }
            
            if let primaryGuy = sortedGuys.first {
                sendNotification(app: primaryGuy.app)
                notifiedApps.insert(primaryGuy.app.bundleIdentifier ?? "shit-happens")
            }
        }

        
        /// OLD LOGIC
        
//        for (app, _) in runningApps {
//            if app.isActive {
//                self.runningApps[app] = now
//            } else {
//                // New efficient approach
//                if let lastTime = self.runningApps[app], now - lastTime > TimeInterval(closingTime * 60) && !notifiedApps.contains(app.bundleIdentifier ?? "") && nonNotifyApps[app.bundleIdentifier ?? ""] != true {
//                    if !quitWithoutNotify {
//                        sendNotification(app: app)
//                        notifiedApps.insert(app.bundleIdentifier ?? "shit-happens")
//                    } else {
//                        quitApp(appID: app.processIdentifier)
//                    }
//                } else {
//                }
//            }
//        }
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
        
        let identifier = app.bundleIdentifier ?? UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
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
//            "com.timpler.screenstudio",
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
//            print("About to stop the timer - \(Date())")
            
            sleepStartTime = Date()
            timer?.invalidate()
            timer = nil
            
        } else {
//            print("About to start the timer again - \(Date())")
            
            let currentTime = Date()
//            print("Difference = \(currentTime.timeIntervalSince(sleepStartTime))")
            
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

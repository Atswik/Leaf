
import Cocoa
import SwiftUI
import Sparkle

class AppDelegate: NSObject, NSApplicationDelegate {

    static var shared: AppDelegate!
    var tracker = Tracker()
    
    let sparkleDelegate = SparkleDelegate()
    var updateController: SPUStandardUpdaterController
    
    var updater: SPUUpdater { updateController.updater }
    
    override init() {
        self.updateController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: sparkleDelegate
        )
        super.init()
    }
    
    var isFirstLaunch: Bool {
        get { UserDefaults.standard.object(forKey: "isFirstLaunch") == nil
              ? true
              : UserDefaults.standard.bool(forKey: "isFirstLaunch") }
        set { UserDefaults.standard.set(newValue, forKey: "isFirstLaunch") }
    }

    static var onboardingWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        if isFirstLaunch {
            AppDelegate.showOnboarding()
        } else {
            tracker.start()
        }
    }

    static func showOnboarding() {
        guard onboardingWindow == nil else {
            onboardingWindow?.makeKeyAndOrderFront(nil)
            return
        }
        let delegate = AppDelegate.shared!
        let binding = Binding(
            get: { delegate.isFirstLaunch },
            set: { delegate.isFirstLaunch = $0 }
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 350),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(
            rootView: OnboardingView(tracker: delegate.tracker, isFirstLaunch: binding)
        )
        onboardingWindow = window
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

import Testing
@testable import Leaf

struct AudioActivityTests {
    private let resolver = AudioOwnershipResolver()

    @Test func treatsInputOrOutputAsAudioActivity() {
        #expect(AudioActivityMonitor.isActive(isRunningOutput: 1, isRunningInput: 0))
        #expect(AudioActivityMonitor.isActive(isRunningOutput: 0, isRunningInput: 1))
        #expect(!AudioActivityMonitor.isActive(isRunningOutput: 0, isRunningInput: 0))
    }

    @Test func resumesNormalTrackingAfterTenAudioFailures() {
        #expect(Tracker.shouldSkipActionsAfterAudioFailure(9))
        #expect(!Tracker.shouldSkipActionsAfterAudioFailure(10))
    }

    @Test func resolvesAudioFromTheAppMainProcess() {
        let app = AudioAppDescriptor(
            processIdentifier: 101,
            bundleIdentifier: "com.example.Player",
            bundlePath: "/Applications/Player.app"
        )

        let owners = resolver.owningAppProcessIdentifiers(for: [101], apps: [app]) { _ in nil }

        #expect(owners == [101])
    }

    @Test func resolvesAudioFromAnAppHelperProcess() {
        let app = AudioAppDescriptor(
            processIdentifier: 101,
            bundleIdentifier: "com.example.Player",
            bundlePath: "/Applications/Player.app"
        )

        let owners = resolver.owningAppProcessIdentifiers(for: [202], apps: [app]) { pid in
            pid == 202 ? "/Applications/Player.app/Contents/Frameworks/AudioHelper" : nil
        }

        #expect(owners == [101])
    }

    @Test func attributesSharedWebKitAudioToSafariOnlyWhenSafariIsRunning() {
        let safari = AudioAppDescriptor(
            processIdentifier: 101,
            bundleIdentifier: "com.apple.Safari",
            bundlePath: "/Applications/Safari.app"
        )
        let sharedWebKitPaths = [
            "/System/Library/Frameworks/WebKit.framework/Versions/A/XPCServices/com.apple.WebKit.WebContent.xpc/Contents/MacOS/com.apple.WebKit.WebContent",
            "/System/Volumes/Preboot/Cryptexes/Incoming/OS/System/Library/Frameworks/WebKit.framework/Versions/A/XPCServices/com.apple.WebKit.GPU.xpc/Contents/MacOS/com.apple.WebKit.GPU"
        ]

        for path in sharedWebKitPaths {
            let withSafari = resolver.owningAppProcessIdentifiers(for: [202], apps: [safari]) { _ in path }
            let withoutSafari = resolver.owningAppProcessIdentifiers(for: [202], apps: []) { _ in path }

            #expect(withSafari == [101])
            #expect(withoutSafari.isEmpty)
        }
    }

    @Test func ignoresAudioFromAnUnownedProcess() {
        let app = AudioAppDescriptor(
            processIdentifier: 101,
            bundleIdentifier: "com.example.Player",
            bundlePath: "/Applications/Player.app"
        )

        let owners = resolver.owningAppProcessIdentifiers(for: [202], apps: [app]) { _ in "/usr/local/bin/other-process" }

        #expect(owners.isEmpty)
    }

    @Test func reportsUnavailableAudioInsteadOfTreatingItAsSilence() {
        let owners = resolver.owningAppProcessIdentifiers(for: .unavailable, apps: [])

        #expect(owners == nil)
    }
}

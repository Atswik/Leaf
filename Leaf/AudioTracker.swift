//
//  AudioTracker.swift
//  Leaf
//
//  Created by Satwik on 6/23/26.
//

import CoreAudio
import Darwin
import Foundation

protocol AudioActivityProviding {
    func snapshot() -> AudioActivitySnapshot
}

enum AudioActivitySnapshot: Equatable {
    case available(Set<pid_t>)
    case unavailable
}

struct AudioActivityMonitor: AudioActivityProviding {

    func snapshot() -> AudioActivitySnapshot {
        var processListAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &processListAddress,
            0, nil,
            &dataSize
        ) == noErr else {
            return .unavailable
        }

        guard dataSize % UInt32(MemoryLayout<AudioObjectID>.size) == 0 else {
            return .unavailable
        }

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        guard count > 0 else {
            return .available([])
        }

        var audioObjectIDs = [AudioObjectID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &processListAddress,
            0, nil,
            &dataSize,
            &audioObjectIDs
        ) == noErr else {
            return .unavailable
        }

        var result = Set<pid_t>()
        let myPID = ProcessInfo.processInfo.processIdentifier

        for objectID in audioObjectIDs {
            var pidAddress = AudioObjectPropertyAddress(
                mSelector: kAudioProcessPropertyPID,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            var pid: pid_t = 0
            var pidSize = UInt32(MemoryLayout<pid_t>.size)
            guard AudioObjectGetPropertyData(
                objectID,
                &pidAddress,
                0, nil,
                &pidSize,
                &pid
            ) == noErr else {
                return .unavailable
            }

            guard pid != myPID else { continue }

            guard let isRunningOutput = runningState(
                for: objectID,
                selector: kAudioProcessPropertyIsRunningOutput
            ), let isRunningInput = runningState(
                for: objectID,
                selector: kAudioProcessPropertyIsRunningInput
            ) else {
                return .unavailable
            }

            if Self.isActive(isRunningOutput: isRunningOutput, isRunningInput: isRunningInput) {
                result.insert(pid)
            }
        }

        return .available(result)
    }

    static func isActive(isRunningOutput: UInt32, isRunningInput: UInt32) -> Bool {
        isRunningOutput != 0 || isRunningInput != 0
    }

    private func runningState(
        for objectID: AudioObjectID,
        selector: AudioObjectPropertySelector
    ) -> UInt32? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var state: UInt32 = 0
        var stateSize = UInt32(MemoryLayout<UInt32>.size)

        guard AudioObjectGetPropertyData(
            objectID,
            &address,
            0, nil,
            &stateSize,
            &state
        ) == noErr else {
            return nil
        }

        return state
    }

}

struct AudioAppDescriptor: Equatable {
    let processIdentifier: pid_t
    let bundleIdentifier: String?
    let bundlePath: String?
}

struct AudioOwnershipResolver {
    private static let safariBundleIdentifier = "com.apple.Safari"
    private static let sharedWebKitFrameworkPath = "/System/Library/Frameworks/WebKit.framework/"
    private static let processPathBufferSize = 4_096

    func owningAppProcessIdentifiers(
        for snapshot: AudioActivitySnapshot,
        apps: [AudioAppDescriptor],
        processPath: (pid_t) -> String? = Self.processPath
    ) -> Set<pid_t>? {
        guard case .available(let audioProcessIdentifiers) = snapshot else {
            return nil
        }
        return owningAppProcessIdentifiers(
            for: audioProcessIdentifiers,
            apps: apps,
            processPath: processPath
        )
    }

    func owningAppProcessIdentifiers(
        for audioProcessIdentifiers: Set<pid_t>,
        apps: [AudioAppDescriptor],
        processPath: (pid_t) -> String? = Self.processPath
    ) -> Set<pid_t> {
        let appPIDs = Set(apps.map(\.processIdentifier))
        let safariPID = apps.first { $0.bundleIdentifier == Self.safariBundleIdentifier }?.processIdentifier
        var owners = Set<pid_t>()

        for pid in audioProcessIdentifiers {
            let path = processPath(pid)
            var owner: AudioAppDescriptor?

            if appPIDs.contains(pid) {
                owner = apps.first { $0.processIdentifier == pid }
            } else if let path {
                if path.contains(Self.sharedWebKitFrameworkPath), let safariPID {
                    owner = apps.first { $0.processIdentifier == safariPID }
                } else {
                    owner = apps
                        .compactMap { app -> (app: AudioAppDescriptor, pathLength: Int)? in
                            guard let bundlePath = app.bundlePath,
                                  path == bundlePath || path.hasPrefix(bundlePath + "/") else {
                                return nil
                            }
                            return (app, bundlePath.count)
                        }
                        .max { $0.pathLength < $1.pathLength }?
                        .app
                }
            }

            if let owner {
                owners.insert(owner.processIdentifier)
            }
        }

        return owners
    }

    static func processPath(for pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: processPathBufferSize)
        let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        guard length > 0 else {
            return nil
        }
        return String(cString: buffer)
    }

}

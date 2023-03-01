import AppKit
import InputMethodKit
import CoreIME

extension DispatchQueue {
        static let dataQueue: DispatchQueue = DispatchQueue(label: "hk.eduhk.inputmethod.Jyutping.data", qos: .userInitiated)
}

struct AppMaster {
        /// Example: 1.0.1 (23)
        static let version: String = {
                let marketingVersion: String = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.1.0"
                let currentProjectVersion: String = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "1"
                return marketingVersion + " (" + currentProjectVersion + ") preview 1"
        }()
}

final class PrincipalApplication: NSApplication {

        private let appDelegate = AppDelegate()

        override init() {
                super.init()
                self.delegate = appDelegate
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError() }
}

@main
final class AppDelegate: NSObject, NSApplicationDelegate {

        private(set) var server: IMKServer?

        func applicationDidFinishLaunching(_ notification: Notification) {
                handleCommandLineArguments()
                let name: String = "hk_eduhk_inputmethod_Jyutping_1_Connection"
                server = IMKServer(name: name, bundleIdentifier: Bundle.main.bundleIdentifier)
                DispatchQueue.dataQueue.async {
                        Engine.prepare(appVersion: AppMaster.version)
                }
        }

        private func handleCommandLineArguments() {
                let shouldInstallIME: Bool = CommandLine.arguments.contains("install")
                guard shouldInstallIME else { return }
                registerIME()
                activateIME()
                NSRunningApplication.current.terminate()
                NSApp.terminate(self)
                exit(0)
        }

        private func registerIME() {
                let url = Bundle.main.bundleURL
                let cfURL = url as CFURL
                TISRegisterInputSource(cfURL)
        }
        private func activateIME() {
                guard let inputSources = TISCreateInputSourceList(nil, true).takeRetainedValue() as? [TISInputSource] else { return }
                let inputSourceID: String = "hk.eduhk.inputmethod.Jyutping"
                let inputModeID: String = "hk.eduhk.inputmethod.Jyutping.IME"
                for item in inputSources {
                        guard let pointer = TISGetInputSourceProperty(item, kTISPropertyInputSourceID) else { return }
                        let sourceID = Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
                        if sourceID == inputSourceID || sourceID == inputModeID {
                                TISDisableInputSource(item)
                                TISEnableInputSource(item)
                        }
                }
        }
}

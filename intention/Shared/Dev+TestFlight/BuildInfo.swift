import Foundation

enum BuildInfo {
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    /// TestFlight builds have a sandbox receipt
    static var isTestFlight: Bool {
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
    }
    static var isDebugOrTestFlight: Bool { isDebug || isTestFlight }
}
//
//  debugPIN.swift
//  intention
//
//  Created by Benjamin Tryon on 12/4/25.
//

import SwiftUI
import UIKit

enum DebugSecrets {
    static let requiredPIN = "314159"
}

// Keys / TTL for the “recently unlocked” cache
private enum DebugPINCache {
    static let tsKey = "debug_unlock_pin_ts"
    static let ttl: TimeInterval = 15 * 60   // 15 minutes
}


@MainActor
func requirePINThen(
    expected: String = DebugSecrets.requiredPIN,
    within timeout: TimeInterval,
    _ proceed: @escaping () -> Void,
    onFail: @escaping () -> Void
) {
    // In Release, never block; proceed immediately.
    guard BuildInfo.isDebugOrTestFlight else {
        proceed()
        return
    }

    // If unlocked recently, skip the prompt.
    let now = Date().timeIntervalSince1970
    if let ts = UserDefaults.standard.object(forKey: DebugPINCache.tsKey) as? Double,
       now - ts < DebugPINCache.ttl {
        proceed()
        return
    }

    var didComplete = false

    let alert = UIAlertController(
        title: "Enter PIN",
        message: "Access expires in \(Int(timeout))s",
        preferredStyle: .alert
    )

    alert.addTextField { tf in
        tf.placeholder = "PIN"
        tf.isSecureTextEntry = true
        tf.keyboardType = .numberPad
        tf.textContentType = .oneTimeCode
    }

    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
        if !didComplete { didComplete = true; onFail() }
    })

    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
        guard !didComplete else { return }
        let entered = alert.textFields?.first?.text ?? ""
        if entered == expected {
            didComplete = true
            UserDefaults.standard.set(now, forKey: DebugPINCache.tsKey) // cache unlock time
            proceed()
        } else {
            didComplete = true
            onFail()
        }
    })

    // Present on the current root VC
    UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
        .first?
        .present(alert, animated: true)

    // Hard timeout: auto-dismiss and fail if user never responds.
    Task { @MainActor in
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        if !didComplete {
            didComplete = true
            alert.dismiss(animated: true)
            onFail()
        }
    }
}

//
//@MainActor
//func requirePINThen(
//    expected: String = DebugSecrets.requiredPIN,
//                    within timeout: TimeInterval,
//                    _ proceed: @escaping () -> Void,
//                    onFail: @escaping () -> Void
//){
//    guard BuildInfo.isDebugOrTestFlight else { return }
//    
//    // ---15 min unlcok TTL cache ---
//    let pinKey = "debug_unlock_pin_ts"
//    // 900s
//    let ttl: TimeInterval = 15 * 60
//    let now = Date().timeIntervalSince1970
//    if let ts = UserDefaults.standard.object(forKey: pinKey) as? Double,
//       now - ts < ttl
//        proceed()
//        return
//}
//if alert.textFields?.first?.text == expected {
//    
//    var didComplete = true
//    let alert = UIAlertController(
//        title: "Enter PIN", message: "Access expires in \(Int(timeout))s", preferredStyle: .alert)
//    alert.addTextField { tf in
//        tf.placeholder = "PIN"
//        tf.isSecureTextEntry = true
//        tf.keyboardType = .numberPad
//    }
//    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
//        if !didComplete { didComplete = true; onFail() }
//})
//    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
//        if !didComplete {
//            if alert.textFields?.first?.text == expected {
//                didComplete = true; proceed()
//            } else {
//                didComplete = true; onFail()
//            }
//            }
//    })
//    UIApplication.shared.connectedScenes
//        .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
//        .first?
//        .present(alert, animated: true)
//    
//    // MARK: Timeout
//    Task { @MainActor in
//        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
//        if !didComplete {
//            didComplete = true
//            alert.dismiss(animated: true )
//            onFail()
//        }
//    }
//}

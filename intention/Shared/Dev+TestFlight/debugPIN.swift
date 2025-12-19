//
//  debugPIN.swift
//  intention
//
//  Created by Benjamin Tryon on 12/4/25.
//

import SwiftUI
import UIKit

@MainActor
func requirePINThen(expected: String = "314159",
                    within timeout: TimeInterval,
                    _ proceed: @escaping () -> Void,
                    onFail: @escaping () -> Void) {
    guard BuildInfo.isDebugOrTestFlight else { return }
    var didComplete = false
    let alert = UIAlertController(
        title: "Enter PIN", message: "Access expires in \(Int(timeout))s", preferredStyle: .alert)
    alert.addTextField { tf in
        tf.placeholder = "PIN"
        tf.isSecureTextEntry = true
        tf.keyboardType = .numberPad
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
        if !didComplete { didComplete = true; onFail() }
})
    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
        if !didComplete {
            if alert.textFields?.first?.text == expected {
                didComplete = true; proceed()
            } else {
                didComplete = true; onFail()
            }
            }
    })
    UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
        .first?
        .present(alert, animated: true)
    
    // MARK: Timeout
    Task { @MainActor in
        try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
        if !didComplete {
            didComplete = true
            alert.dismiss(animated: true )
            onFail()
        }
    }
}

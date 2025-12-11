//
//  debugPIN.swift
//  intention
//
//  Created by Benjamin Tryon on 12/4/25.
//

import SwiftUI
import UIKit

@MainActor
func requirePINThen(expected: String = "1521", proceed: @escaping () -> Void) {
    guard BuildInfo.isDebugOrTestFlight else { return }
    let alert = UIAlertController(title: "Enter PIN", message: nil, preferredStyle: .alert)
    alert.addTextField { tf in
        tf.placeholder = "PIN"
        tf.isSecureTextEntry = true
        tf.keyboardType = .numberPad
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
        if alert.textFields?.first?.text == expected { proceed() }
    })
    UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
        .first?
        .present(alert, animated: true)
}

//
//func requirePINThen(_ proceed: @escaping () -> Void) {
//    guard BuildInfo.isDebugOrTestFlight else { return }
//    let expected = "3141"
//    let alert = UIAlertController(title: "Enter PIN", message: nil, preferredStyle: .alert)
//    alert.addTextField { tf in
//        tf.placeholder = "PIN"
//        tf.isSecureTextEntry = true
//        tf.keyboardType = .numberPad
//    }
//    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
//        if alert.textFields?.first?.text == expected { proceed() }
//    })
//    UIApplication.shared.connectedScenes
//        .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
//        .first?
//        .present(alert, animated: true)
//}

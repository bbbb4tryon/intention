//
//  SystemAlertPresenter.swift
//  intention
//
//  Created by Benjamin Tryon on 12/20/25.
//

//import SwiftUI

// === USE: to make alerts Apple default look ===
//    .alert("Cancel?", isPresented: $showCancelConfirm) {
//  -            Button("Go Back", role: .cancel) { }
//  -            Button("Cancel Session", role: .destructive) {
//  -                focusVM.performAsyncAction {
//  -                    await focusVM.resetSessionStateForNewStart()
//  -                }
//  -            }
//  -        } message: {
//  -            Text("Stop timer, clear all tiles.")
//  -        }
//          .systemAlert(
//              "Cancel?",
//              isPresented: $showCancelConfirm,
//              message: "Stop timer, clear all tiles.",
//              actions: [
//                  SystemAlertAction("Go Back", role: .cancel),
//                  SystemAlertAction("Cancel Session", role: .destructive) {
//                      focusVM.performAsyncAction { await focusVM.resetSessionStateForNewStart() }
//                  }
//              ]
//          )
// === USE ===
//
//struct SystemAlertPresenter: UIViewControllerRepresentable {
//    @Binding var isPresented: Bool
//    let title: String
//    let message: String
//    let actions: [SystemAlertAction]
//
//    func makeUIViewController(context: Context) -> UIViewController {
//        UIViewController()
//    }
//
//    func updateUIViewController(_ vc: UIViewController, context: Context) {
//        guard isPresented, vc.presentedViewController == nil else { return }
//
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        actions.forEach { a in
//            alert.addAction(UIAlertAction(title: a.title,
//                                          style: a.role.uiStyle,
//                                          handler: { _ in a.handler?(); }))
//        }
//        vc.present(alert, animated: true) { isPresented = false }
//    }
//}
//
//struct SystemAlertAction {
//    enum Role { case cancel, destructive, `default` }
//    let title: String
//    let role: Role
//    let handler: (() -> Void)?
//
//    init(_ title: String, role: Role = .default, handler: (() -> Void)? = nil) {
//        self.title = title; self.role = role; self.handler = handler
//    }
//
//    fileprivate var uiStyle: UIAlertAction.Style {
//        switch role {
//        case .cancel: return .cancel
//        case .destructive: return .destructive
//        case .default: return .default
//        }
//    }
//}
//
//extension View {
//    func systemAlert(_ title: String,
//                     isPresented: Binding<Bool>,
//                     message: String,
//                     actions: [SystemAlertAction]) -> some View {
//        background(SystemAlertPresenter(isPresented: isPresented,
//                                        title: title,
//                                        message: message,
//                                        actions: actions))
//    }
//}

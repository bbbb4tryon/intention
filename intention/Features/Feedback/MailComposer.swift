//
//  MailComposer.swift
//  intention
//
//  Created by Benjamin Tryon on 10/21/25.
//


import MessageUI
import SwiftUI

struct MailComposer: UIViewControllerRepresentable {
    let to: [String]
    let subject: String
    let body: String
//    let onComplete: (Result<Void, Error>) -> Void
    // MFMailComposeResult: .sent, .cancelled, .saved, .failed
    let onComplete: (MFMailComposeResult, Error?) -> Void

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposer
        init(_ parent: MailComposer) { self.parent = parent }
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true) {
//                if let error { self.parent.onComplete(.failure(error)) }
//                else { self.parent.onComplete(.success(())) }
                self.parent.onComplete(result, error)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(to)
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}

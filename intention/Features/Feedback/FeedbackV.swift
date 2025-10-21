//
//  FeedbackV.swift
//  intention
//
//  Created by Benjamin Tryon on 10/21/25.
//

import MessageUI
import SwiftUI

struct FeedbackV: View {
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var prefs: AppPreferencesVM
    
    @Environment(\.openURL) private var openURL

    // Inputs
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var userID: String = "" // auto-filled

    // Validation states
    @State private var nameState: ValidationState = .none      // optional
    @State private var emailState: ValidationState = .none     // required
    @State private var messageState: ValidationState = .none   // required

    @State private var showComposer = false
    @State private var composerPayload: (subject: String, body: String)? = nil
    @State private var showingAlert = false
    @State private var alertMsg = ""

    private let maxMessageChars = 2000
    private let screen: ScreenName = .settings
    private var p: ScreenStylePalette { theme.palette(for: screen) }
    private var T: (String, TextRole) -> Text {
        { key, role in theme.styledText(key, as: role, in: screen) }
    }
    
    var body: some View {
        // Email body with useful info for bug reports
//        let body = "\n\nApp Version: \(version)\nDevice: \(deviceType)\niOS: \(osVersion)"
        
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                T("Send Feedback", .header)

                Group {
                    T("Name (optional)", .label)
                    TextField("Jane Doe", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                        .validatingField(state: nameState, palette: p)
                }

                Group {
                    T("Email (required)", .label)
                    TextField("name@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .validatingField(state: emailState, palette: p)
                    ValidationCaption(state: emailState, palette: p)
                }

                Group {
                    HStack {
                        T("Message", .label)
                        Spacer()
                        Text("\(message.count)/\(maxMessageChars)")
                            .font(.caption)
                            .foregroundStyle(p.textSecondary)
                            .monospacedDigit()
                    }

                    TextEditor(text: $message)
                        .frame(minHeight: 160)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .padding(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(messageState.isInvalid ? p.danger : p.border, lineWidth: 1)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.clear)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    ValidationCaption(state: messageState, palette: p)
                }

                // Auto insert userID/deviceID from your Keychain helper
                T("Device ID: \(userID)", .caption)
                    .foregroundStyle(p.textSecondary)
                    .textSelection(.enabled)

                Button(action: sendTapped) {
                    T("Send", .action)
                        .monospacedDigit()
                }
                .primaryActionStyle(screen: screen)
                .disabled(!canSend)
            }
            .padding(20)
            .frame(maxWidth: 700, alignment: .leading)
        }
        .background(p.background.ignoresSafeArea())
        .tint(p.accent)
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively) // swipe down to dismiss
        .safeAreaInset(edge: .bottom) {
            // keeps content visible above the keyboard on small screens
            Color.clear.frame(height: 8)
        }
        .onAppear {
            Task { @MainActor in
                userID = await KeychainHelper.shared.getUserIdentifier()
            }
        }
        // Mail composer (native), with graceful fallback if not available
        .sheet(isPresented: $showComposer) {
            if MFMailComposeViewController.canSendMail(), let payload = composerPayload {
                MailComposer(
                    to: ["feedback@argonnesoftware.com"],
                    subject: payload.subject,
                    body: payload.body
                ) { result in
                    switch result {
                    case .success:
                        alertMsg = "Thanks! Feedback sent!"
                    case .failure(let err):
                        alertMsg = "Could not send: \(err.localizedDescription)"
                    }
                    showingAlert = true
                }
            } else {
                // Fallback shouldn’t appear as a sheet; we’ll use openURL instead.
                EmptyView()
            }
        }
        .alert("Feedback", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: { Text(alertMsg) }
        .onChange(of: message) { new in
            if new.count > maxMessageChars {
                message = String(new.prefix(maxMessageChars))
            }
        }
    }

    private var canSend: Bool {
        emailIsValid(email) && !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sendTapped() {
        // validate now (gate surfacing)
        emailState = emailIsValid(email) ? .valid : .invalid(messages: ["Enter a valid email address."])
        messageState = message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? .invalid(messages: ["Message can’t be empty."])
            : .valid
        guard canSend else { return }

        let subject = "Intendly Feedback"
        let body = composedBody()
        composerPayload = (subject, body)

        // 1) Try user's default mail client via mailto:
        if openMailTo(subject: subject, body: body) {
            alertMsg = "Your mail app was opened with a pre-filled message."
            showingAlert = true
            return
        }

        // 2) Fallback to in-app composer (Apple Mail backend)
        if MFMailComposeViewController.canSendMail() {
            showComposer = true
            return
        }

        // 3) No handler + no Mail account: show a helpful message
        alertMsg = "No mail app available. Please configure a mail app or copy your message."
        showingAlert = true
    }
    
    /// Returns true if we successfully opened a mail client.
    @discardableResult
    private func openMailTo(subject: String, body: String) -> Bool {
        let to = "feedback@argonnesoftware.com"

        var comps = URLComponents()
        comps.scheme = "mailto"
        comps.path = to
        comps.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]

        guard let url = comps.url else { return false }

        // Prefer the environment's openURL (respects scene), but also probe UIApplication as a fallback.
        var opened = false
        openURL(url) { success in opened = success }
        if opened { return true }

        // Fallback probe (some contexts call this synchronously)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return true
        }

        return false
    }



    private func composedBody() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let sys = UIDevice.current.systemVersion
        let model = UIDevice.current.model

        return """
        Name: \(name.isEmpty ? "(not provided)" : name)
        Email: \(email)
        Device ID: \(userID)
        App: \(appVersion) (\(build)) • iOS \(sys) • \(model)

        ---- Message ----
        \(message)
        """
    }

    private func fallbackMailToIfNeeded() {
        guard let payload = composerPayload else { return }
        // URL-encode (simple)
        let to = "feedback@argonnesoftware.com"
        let subject = payload.subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Feedback"
        let body = payload.body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(to)?subject=\(subject)&body=\(body)") {
            UIApplication.shared.open(url)
        } else {
            alertMsg = "No Mail account is configured and I couldn’t open a mailto: link."
            showingAlert = true
        }
    }

    private func emailIsValid(_ s: String) -> Bool {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= 254 else { return false }
        // Lightweight validation: one @ and at least one dot after
        let parts = trimmed.split(separator: "@")
        guard parts.count == 2, parts[0].count >= 1 else { return false }
        return parts[1].contains(".")
    }
}

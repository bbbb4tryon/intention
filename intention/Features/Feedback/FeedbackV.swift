//
//  FeedbackV.swift
//  intention
//
//  Created by Benjamin Tryon on 10/21/25.
//

import MessageUI
import SwiftUI


private extension View {
    @ViewBuilder func cardBackground() -> some View {
        background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        //TODO: Or use .shadow(radius: 3, y: 1)
    }
    @ViewBuilder func fieldClip() -> some View {
        clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

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
    private var T: (String, TextRole) -> Text { { key, role in theme.styledText(key, as: role, in: screen) } }
    
    // --- Local Color Definitions for FeedbackV ---
    private let textSecondary = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.72)
    private let colorBorder = Color(red: 0.333, green: 0.333, blue: 0.333).opacity(0.22)
    private let colorDanger = Color.red
    
    // MARK: Precomputes
    private var trimmedMessage: String {
        message.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var messageCountText: String { "\(message.count)/\(maxMessageChars)" }
    private var deviceRowText: String { "Device ID: \(userID)" }
    // --- MAYBE THESE TOO? ---
    private var fieldStrokeShape: RoundedRectangle { .init(cornerRadius: 10, style: .continuous) }
    private var cardShape: RoundedRectangle { .init(cornerRadius: 12, style: .continuous) }
    
    
    // MARK: Section: Header
    @ViewBuilder private var headerRow: some View {
        T("Send Feedback", .header)
        //TODO: Or use .shadow(radius: 3, y: 1)
    }
    
    // MARK: Section: Name
    @ViewBuilder private var nameSection: some View {
        Group {
            T("Name (optional)", .label)
            Spacer()
            TextField("Jane Doe", text: $name)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(false)
                .validatingField(state: nameState, palette: p)
        }
    }
    
    // MARK: Section: Email
    @ViewBuilder private var emailSection: some View {
        Group {
            T("Email (required)", .label)
            
            Spacer()
            TextField("name@example.com", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .validatingField(state: emailState, palette: p)
            ValidationCaption(state: emailState)
        }
    }
    
    // MARK: Section: Message
    @ViewBuilder private var messageSection: some View {
        Group {
            HStack {
                T("Message", .label)
                
                Spacer()
                Text(messageCountText)
                    .font(.caption)
                    .foregroundStyle(textSecondary)
                    .monospacedDigit()
            }
            
            TextEditor(text: $message)
                .frame(minHeight: 160)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(false)
                .padding(12)
                .overlay(
                    fieldStrokeShape
                        .stroke(messageState.isInvalid ? colorDanger : colorBorder, lineWidth: 1)
                )
                .background(fieldStrokeShape.fill(p.background.opacity(0.0001))) // keeps hit-testing safe
                .fieldClip()
            ValidationCaption(state: messageState)
        }
    }
    
    // MARK: Section: Device Row
    @ViewBuilder private var deviceRow: some View {
        // Auto insert userID/deviceID from your Keychain helper
        T(deviceRowText, .caption)
            .foregroundStyle(textSecondary)
            .textSelection(.enabled)
    }
    
    // MARK: Section: Send button
    @ViewBuilder private var sendButtonSection: some View {
        Button(action: sendTapped) {
            T("Send", .action)
                .monospacedDigit()
        }
        .primaryActionStyle(screen: screen)
        .disabled(!canSend)
    }
    
    // Keep the heavy sheet content out of the main body closure
    // MARK: Mail sheet content
    @ViewBuilder private var composerSheet: some View {
        if MFMailComposeViewController.canSendMail(), let payload = composerPayload {
            MailComposer(
                to: ["feedback@argonnesoftware.com"],
                subject: payload.subject,
                body: payload.body
            ) { result, err in
                switch result {
                case .sent:
                    alertMsg = "Thanks! Feedback sent!"; showingAlert = true
                case .failed:
                    alertMsg = "Could not send: \(err?.localizedDescription ??  "Unknown error")"; showingAlert = true
                case .saved, .cancelled:
                    // backed out or saved draft - no alert
                    break
                @unknown default:
                    break
                }
            }
        } else {
            // Fallback shouldn’t appear as a sheet; we’ll use openURL instead.
            EmptyView()
        }
    }
    
    // MARK: CanSend: Bool
    private var canSend: Bool {
        emailIsValid(email) && !trimmedMessage.isEmpty
    }
    
    var body: some View {
        // Email body with useful info for bug reports
        //        let body = "\n\nApp Version: \(version)\nDevice: \(deviceType)\niOS: \(osVersion)"
        
        ScrollView {
            Page(top: 4, alignment: .leading) {
                T("Feedback", .header)
                    .padding(.bottom, 4)
                
                Card {  nameSection }
                Card { emailSection }
                Card { messageSection }
                Card { deviceRow }
                Card { sendButtonSection }
            }
            //            .padding(20)
            //            .frame(maxWidth: 700, alignment: .leading)
        }
        .background(p.background.ignoresSafeArea())
        .tint(p.accent)
        .navigationTitle("Feedback")
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        //TODO: Or use .shadow(radius: 3, y: 1)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively) // swipe down to dismiss
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 8).zIndex(0) } // keeps content visible above the keyboard on small screens
        .onAppear {
            // Keychain won't get involved in previews, only in real runs
            if IS_PREVIEW {
                userID = "PREVIEW-DEVICE-ID"
            } else {
                Task { @MainActor in
                    userID = await KeychainHelper.shared.getUserIdentifier()
                }
            }
        }
        .sheet(isPresented: $showComposer) { composerSheet }
        .alert("Feedback", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMsg)
        }
        .onChange(of: message) { new in
            if new.count > maxMessageChars {
                message = String(new.prefix(maxMessageChars))
            }
        }
    }
    
    /// Returns true if we successfully opened a mail client.
    /// UIApplication callers @MainActor (they already run on main, but this clarifies actor isolation)
    // MARK: - MainActor OpenMainTo()
    @MainActor
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
    
    // MARK: - SendTapped()
    @MainActor
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
//        
//        // 1) Try user's default mail client via mailto:
//        if openMailTo(subject: subject, body: body) {
//            alertMsg = "Your mail app was opened with a pre-filled message."
//            showingAlert = true
//            return
//        }
        
        if MFMailComposeViewController.canSendMail() {
            // prefer in-app composer -> definite sent/failed callback
            showComposer = true
            return
        }
        
        // fallback to user's default mail app via mailto: (no alert needed)
        if openMailTo(subject: subject, body: body) {
            return
        }
        
        // no handler + no Mail account: show a helpful message
        alertMsg = "No mail app available. Please configure a mail app or copy your message."
        showingAlert = true
    }
    
    // MARK: ComposedBody()
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

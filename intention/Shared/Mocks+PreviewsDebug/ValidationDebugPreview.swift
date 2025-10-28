//
//  ValidationDebugPreview.swift
//  intention
//
//  Created by Benjamin Tryon on 10/1/25.
//

#if DEBUG
import SwiftUI

// MARK: - Validation Debug Preview

/// Use this view to test all ValidationState cases, border colors, and captions.
@MainActor
struct ValidationDebugPreview: View {
    
    // 1. Fetch the necessary environment objects
    @EnvironmentObject var theme: ThemeManager
    
    // 2. State variables for testing
    @State private var inputText: String = ""
    @State private var showValidation: Bool = false // The 'on submit' gate
    @State private var scenario: Scenario = .default

    // Use the ThemeManager to get the current palette, just like FocusSessionActiveV
    private var p: ScreenStylePalette { 
        // Assuming you have a ScreenName for this preview, or use a known one
        theme.palette(for: .focus) 
    }
    
    // Mimics the vState computed property from FocusSessionActiveV
    private var computedValidationState: ValidationState {
        // This relies on the String extensions from ValidationResults+Fuzzy.swift
        guard showValidation else { return .none }
        
        // This calls your existing validation logic
        let msgs = inputText.taskValidationMessages 
        return msgs.isEmpty ? .valid : .invalid(messages: msgs)
    }

    // A simple enum to switch between demo cases quickly
    enum Scenario: String, CaseIterable, Identifiable {
        case `default` = "0. Initial: .none (Charcoal border)"
        case invalidEmpty = "1. Invalid: Empty (Red border + Caption)"
        case invalidLong = "2. Invalid: Too long (Red border + Caption)"
        case valid = "3. Valid (Standard border, No Caption)"
        var id: String { rawValue }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            
            Text("Validation Field Tester (iPhone 15, iOS 16+)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(p.text)
            
            // ------------------------------------
            // INTERACTIVE DEBUG CONTROLS
            // ------------------------------------
            Group {
                Picker("Debug Scenario", selection: $scenario) {
                    ForEach(Scenario.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: scenario) { newValue in
                    applyScenario(newValue)
                }
                .animation(.none, value: scenario) // Prevent animation on scenario change

                Toggle("Show Validation Errors (Simulate Submit)", isOn: $showValidation)
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // ------------------------------------
            // THE COMPONENT UNDER TEST
            // ------------------------------------
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Task Input Field")
                    .font(.headline)
                    .foregroundStyle(p.text)
                
                // 1. The TextField using your ValidatingField modifier
                TextField("Add Your Intended Task", text: $inputText)
                    .validatingField(state: computedValidationState, palette: p)
                    .animation(.easeInOut(duration: 0.2), value: computedValidationState.isInvalid)

                // 2. The ValidationCaption below the field
                ValidationCaption(state: computedValidationState)
                    .animation(.easeInOut(duration: 0.2), value: computedValidationState.isInvalid)
            }
            
            Spacer()
        }
        .padding()
        .background(p.background.edgesIgnoringSafeArea(.all))
        .onAppear {
            applyScenario(scenario)
        }
    }

    // Function to apply the selected debug state
    func applyScenario(_ scenario: Scenario) {
        switch scenario {
        case .default:
            inputText = "Initial text."
            showValidation = false
        case .invalidEmpty:
            inputText = " "
            showValidation = true
        case .valid:
            inputText = "This is a great intention that is well within the 200 character limit."
            showValidation = true
        case .invalidLong:
            // Create a string over 200 characters
            inputText = String(repeating: "The task is to be repeated over and over and over and over and over and over and over and over and over.", count: 6)
            showValidation = true
        }
    }
}

// MARK: - Preview Setup

struct ValidationDebugPreview_Previews: PreviewProvider {
    static var previews: some View {
        // Use your existing wrapper to inject all required EnvironmentObjects
        PreviewWrapper { 
            ValidationDebugPreview()
        }
        .previewDevice("iPhone 15")
    }
}
#endif

//
//  FocusSessionActiveV.swift
//  intention
//
//  Created by Benjamin Tryon on 6/11/25.
//

import SwiftUI

// FocusSessionActiveV <--> ContentView
// MARK: - Folder Layout (Feature-Based, SwiftUI + UIKit + Actors)

/*
📂 intention
├── App/
│   └── IntentionApp.swift                    // App entry point
│
├── Features/
│   ├── FocusSession/
│   │   ├── FocusSessionV.swift            // UI: shows active session and tiles
│   │   ├── FocusSessionVM.swift       // ObservableObject with tile logic
│   │   ├── FocusTimerActor.swift             // concurrency-safe singleton actor managing 20-min windows
│   │   └── FocusTile.swift                   // model for input tiles
│   |
|   ├── CheckIn/
│   │   ├── CheckInV.swift
│   │   ├── CheckInVM.swift
│   │   └── CheckInService.swift│
|   |
│   ├── Mindfulness/
│   │   └── MindfulnessV.swift             // triggered after 2 sessions
|   |   └── MindfulnessVM.swift
│   │
│   ├── Profile/
│   │   └── ProfileV.swift                 // view history of completed todos
│   │   └── ProfileVM.swift
│   │   └── ArchivedTodos.swift
│   │
│   ├── SocialSharing/
│   │   └── ShareService.swift                // sharing logic (US/China)
│   │   └── SocialMediaBlip.swift
│   │   └── ShareCoordinator.swift
│   │
│   └── Archive/
│       └── ArchiveActor.swift                // manages sliding archive list
│
├── Shared/
│   ├── Components/ - buttons, modals, etc
│   │   └── TileInputView.swift               // reusable tile-as-input UI
│   ├── Helpers/    - utilities STATELESS
│   │   └── DateHelper.swift
│   ├── Extensions/ - utilities
│   │   └── View+Glow.swift, .hexColor                   //
│   ├── Services/   - utilities PERSISTENCE, networking, 3rd party APIs
│   │   └── AppIconProvider.swift
│   └── Resources/
│       └── Colors.xcassets, LaunchScreen, etc
│   └── DesignSystem/
│       └── Typography/
│          ├── AppFontTheme.swift           // font enum
│          ├── Font+Theme.swift             // toFont(), styledHeader()
│
│       └── Colors/
│          ├── AppColorTheme.swift          // main palette
│          ├── ScreenName.swift             // enum case .focusSession, .profile, etc.
│          ├── ColorTheme+Screen.swift      // ScreenColorPalette + .colors(for:)
│
│       └── Layout/
│          ├── Layout+Constants.swift       // cornerRadius, padding, etc.
│          ├── View+Glow.swift              // animation & shadows
│
│       └── Buttons/
│          ├── ButtonConfig+Style.swift     // reusable button style
│
├── Protocols or Generics/
│   └── for abstraction, later
│
├── ViewModels/
│   └── observableObjects, logic containers
|
├── Models/ - codeable structs or domain-layer types
│   └── Tile.swift
|   └── TodoItem.swift
|   └── User.swift
│
├── Concurrency/
│   ├── MainActorIsolated.swift
│   ├── TileManagerActor.swift
│   └── CompletionActor.swift
│
├── Persistence/
│   ├── StorageService.swift
│   ├── LocalFileStore.swift
│
├── Actors/
│   └── concurrency-safe singleton or shared logic
|
|
 Handle, not crash unless app is in danger; Include a large number of fast, well-isolated unit tests to cover your app’s logic, a smaller number of integration tests to demonstrate that smaller parts connect together properly, and UI tests to assert the correct behavior of common use cases; performance tests to provide regression coverage of performance-critical regions of code
 //create a test plan to run only the unit tests for a module while developing and debugging that module, and a second test plan to run all unit, integration, and UI tests before submitting your app to the App Store
 
 
*/
/*
 act as an xcode and swift expert. I don't know how to start testing my iphone app and probably should. Since I am creating the app as a side project, I don't want to be overwhelmed, but want the help of tests and errors.   I don't want the app to ever crash unless it's dire. I would like handling, instead. Test results or informative-and-easy-to-use-and-easy-to-create error handling. Which should I do first or start?

 Apple says use both SwiftTesting and XcodeXCTesting. Handle, not crash unless app is in danger; Include a large number of fast, well-isolated unit tests to cover your app’s logic, a smaller number of integration tests to demonstrate that smaller parts connect together properly, and UI tests to assert the correct behavior of common use cases; performance tests to provide regression coverage of performance-critical regions of code
  //create a test plan to run only the unit tests for a module while developing and debugging that module, and a second test plan to run all unit, integration, and UI tests before submitting your app to the App Store.

 1. Where are resources for quickly getting up to speed EXCEPT apple documentation, which is not my favorite resource to start anything on?
 2. I think a generic test result is best, that is, instead of the test requiring the specific text, I'd rather have test require not empty, not gobbledegook, not malicious and with character and string-length limits or other limits.
 
 int_brown    #A29877    Serious, grounded — titles, text, nav
 int_green    #226E64    Primary action, intentionality, focus, actions/buttons
 int_mint    #8FD8BC    Calm, welcoming — perfect for profile
 int_moss    #B7CFAF    Soft support — secondary elements
 int_sea_green    #50D7B7    Dynamic/energetic — timers, progress, Animations
 int_tan    #E9DCBC    Neutral background (light mode)
 int_tan (Dark)    #7F7457    Neutral background (dark mode)
 */
import SwiftUI

enum ActiveSessionError: Error, Equatable {
    case submitFailed
}

struct FocusSessionActiveV: View {
    @AppStorage("colorTheme") private var colorTheme: AppColorTheme = .default
    @AppStorage("fontTheme") private var fontTheme: AppFontTheme = .serif
    
    @State private var showRecalibrationModal = false
    @State private var selectedChoice: RecalibrationTheme = .breathing

    @StateObject var viewModel = FocusSessionVM()
    @StateObject private var recalibrationVM = RecalibrationVM()
    
    var body: some View {
        
        let palette = colorTheme.colors(for: .homeActiveIntentions)
        
        VStack(spacing: Layout.verticalSpacing){
            //            Helper_AppIconV()
            //                .clipShape(Circle())
            //                .glow(color: .intTan, radius: 12)
            Text.stylingExtension("Intention, Tracked", palette: palette)
            Text.stylingExtension("Uses StylingExtension and palette", palette: palette)
            Text("Intention, Tracked")
//                .foregroundStyle(font: toFont(fontTheme).titleFont)
            
            TextField("Enter intention", text: $viewModel.tileText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(!viewModel.canAdd)    // opaque until 2 added
            
            Button("Submit"){
                Task {
                    guard ((try? await viewModel.submitTile()) != nil) else {
                        throw ActiveSessionError.submitFailed
                    }
                   
                }
            }
            .disabled(!viewModel.canAdd)
            .buttonStyle(.borderedProminent)
            
                if viewModel.tiles.count < 2 {
                    Text("Press Enter When Done")
                } else if viewModel.tiles.count == 2 && viewModel.sessionActive {
                    Text("Session started...")
                        .foregroundStyle(.gray)
                        .animation(
                            .easeInOut.delay(0.1)
                        )
                    
                }
                    
            List(viewModel.tiles) {tile in
                Text(tile.text)
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .navigationTitle("Home - Active Intentions")
        .task {
            await viewModel.startSession()
        }
        .sheet(isPresented: $showRecalibrationModal) {
            RecalibrateV(viewModel: recalibrationVM, recalibrationChoice: selectedChoice)
        }
        
        /*  - a double-sheet, edits and slides - do I need it?
        .sheet(
            isPresented: viewStore.binding(
                get: \.isSheetPresented,
                send: { _ in .setSheet(.none)}
            )) {
                self.sheetContent(for: viewStore.currentSheet)
            }
         */
    }

}

#Preview {
    FocusSessionActiveV()
}

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
    @Environment(\.dismiss) var dismiss
    
    @StateObject var viewModel = FocusSessionVM()   // ViewModel is the source of truth
    @StateObject private var recalibrationVM = RecalibrationVM()
    
    var body: some View {
        
        let palette = colorTheme.colors(for: .homeActiveIntentions)
        
        VStack {
            
            //            Helper_AppIconV()
            //                .clipShape(Circle())
            //                .glow(color: .intTan, radius: 12)
            
            
            Text.styled("Intention, Tracked", as: .header, using: fontTheme, in: palette)
            
            Spacer()    // pushes content towards center-top
            
            // MARK: - Textfield for intention tile text input
            TextField("Enter intention", text: $viewModel.tileText)
                .padding(.bottom, 5)        // small padding to separate visually?
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(viewModel.phase == .running)
                .disabled(viewModel.tiles.count == 2)
            
            // MARK: Main Action Button (Add or Begin)
            if !viewModel.showRecalibrate && viewModel.phase != .running {
                Button(action: {
                    Task {
                        do {
                            if viewModel.tiles.count < 2 {      // Logic adding tiles
                                try await viewModel.addTileAndPrepareForSession()
                            } else if viewModel.tiles.count == 2 && viewModel.phase == .notStarted { // Logic starting session
                                try await viewModel.beginOverallSession()
                            }
                        } catch FocusSessionError.emptyInput {
                            debugPrint("Error: empty input for tile.")
                            print("Must have input")
                        } catch FocusSessionError.tooManyTiles {
                            debugPrint("Error: too many tiles")
                            print("Two list item limit")
                        } catch FocusSessionError.unexpected {
                            debugPrint("Error: FocusSessionError.unexpected: \(FocusSessionError.unexpected)")
                            print("An unexpected error occured: contact the developer")
                        }
                    }
                }) {
                    // MARK: Button label changes based on tile count
                    Text(viewModel.tiles.count < 2 ? "Add" : "Begin")
                }
                .mainActionStyle()
                // Disable if no text in TextField when trying to Add, OR if 2 tiles are added and already started (though not visibile on UI)
                .disabled(viewModel.tiles.count < 2 && viewModel.tileText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
                
                // MARK: Countdown display (user-facing)
                Text.styled("\(viewModel.formattedTime)", as: .caption, using: fontTheme, in: palette)
                //.font(.system(size: 80, weight: .bold, design: .monospaced)) // Large, fixed-width font //FIXME: NEED THIS?
                
                // MARK: - Action Button + Tile Control Flow & Button opacity/activeness
                // Most constrained state: Session is fully complete, time for recalibration
                if viewModel.showRecalibrate {
                    VStack {
                        Text.styled("Session complete! Ready for recalibration?", as: .header, using: fontTheme, in: palette)
                        // if yes, send to recalibration; if no, send back to text input screen
                        
                        Button("Recalibrate Now"){  // <- button acknowledges prompt; sheet presented logic at bottom
                            debugPrint("Recalibrate model presented?")
                        }.mainActionStyle()
                        
                        Button("Start a new session"){
                            viewModel.showRecalibrate = false   // Dismiss the sheet
                            // Reset VM and clear tiles
                            Task {
                                await viewModel.resetSessionStateForNewStart()
                            }
                        }.mainActionStyle()
                    }
                    // Second most constrained state:
                    //  2 tiles logged, *first* 20-min chunk has ended; overall session still in progress
                    //  currentSessionChunk is 1 and phase/chunk 2 not running
                } else if viewModel.tiles.count == 2 && viewModel.currentSessionChunk == 1 && viewModel.phase == .finished {
                    VStack {
                        Text.styled("Completed the first intended item!", as: .header, using: fontTheme, in: palette)
                        
                        Button("Start Next 20 Minutes")
                        {
                            viewModel.startCurrent20MinCountdown()
                        }
                        .mainActionStyle()
                        
                        
                        Button("Start Next Intention")
                        {
                            viewModel.showRecalibrate = false   // Dismisses the sheet
                            Task {
                                guard ((try? await viewModel.startCurrent20MinCountdown()) != nil) else {
                                    throw ActiveSessionError.submitFailed
                                }    // Start the countdown for the second chunk
                            }
                            debugPrint("NextIntention button pressed.")
                            print("`Start Next Intention` button pressed")
                        }.mainActionStyle()
                        
                        //FIXME: End session early button - styling????
                        Button("End Session Early") {
                            Task {
                                guard ((try? await viewModel.resetSessionStateForNewStart()) != nil) else {
                                    throw ActiveSessionError.submitFailed
                                }
                            }
                            debugPrint("EndSession button pressed, User ended session early.")
                            print("Session ended early.")
                        }.notMainActionStyle()
                            .buttonStyle(.bordered)
                            .foregroundStyle(.red)
                    }
                    // General state:
                    //  1st or 2nd tile are active, their countdown and the Overall Session countdown are running
                } else if viewModel.phase == .running {
                    Text("Session in progress...")
                        .foregroundStyle(.gray)
                        .animation(.easeInOut.delay(0.1))
                    // Initial state:
                    //      No tiles added yet, or only one tile added, or 2 tiles have been added but session hasn't begun
                } else if viewModel.tiles.count < 2 && (viewModel.tiles.count == 2 && viewModel.phase == .notStarted) {
                    Text("Enter Your Intention and Press `\(viewModel.tiles.count < 2 ? "Add" : "Begin")`")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                // MARK: - List: Tile container
                VStack {
                    List(viewModel.tiles) {tile in
                        Text(tile.text)
                    }
                    .listStyle(.grouped)
                }
                .background(palette.background)
            }
        }
        .background(palette.background)
        .padding(.horizontal, Layout.horizontalPadding)
        .navigationTitle("Home - Active Intentions")
        .sheet(isPresented: $viewModel.showRecalibrate){
            RecalibrateV(viewModel: recalibrationVM) // FIXME: NEED recalibrationChoice: selectedChoice?
        }
    }
}

#Preview {
    FocusSessionActiveV()
}

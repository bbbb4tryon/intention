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
    case submitFailed, sessionAlreadyRunning
}

struct FocusSessionActiveV: View {
    @AppStorage("colorTheme") private var colorTheme: AppColorTheme = .default
    @AppStorage("fontTheme") private var fontTheme: AppFontTheme = .serif
    @Environment(\.dismiss) var dismiss
    
    @StateObject var viewModel = FocusSessionVM()   // ViewModel is the source of truth
    @StateObject private var recalibrationVM = RecalibrationVM()
    
    var body: some View {
        
        let palette = colorTheme.colors(for: .homeActiveIntentions)
        NavigationView {
            VStack(spacing: 20){
//                    Helper_AppIconV()
//                        .clipShape(Circle())
//                        .glow(color: .intTan, radius: 12)
                    Text.styled("Intention, Tracked", as: .header, using: fontTheme, in: palette)
                        .font(.largeTitle).bold()
                        .padding(.bottom, 10)
                
                Spacer()    // pushes content towards center-top
                
                // MARK: - Textfield for intention tile text input
                TextField("Enter intention", text: $viewModel.tileText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(viewModel.tiles.count == 2 && viewModel.phase == .running)
                    .padding(.horizontal)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.sentences)
                
                // MARK: Main Action Button (Add or Begin)
                if !viewModel.showRecalibrate && viewModel.phase != .running {
                    Button(action: {
                        Task {
                            do {
                                if viewModel.tiles.count < 2 {      // Logic adding tiles
                                    guard ((try?  await viewModel.addTileAndPrepareForSession()) != nil) else {
                                        throw FocusSessionError.badTrigger_Overall
                                    }
                                } else if viewModel.tiles.count == 2 && viewModel.phase == .notStarted { // Logic starting session
                                    guard ((try? await viewModel.beginOverallSession()) != nil) else {
                                        throw ActiveSessionError.sessionAlreadyRunning
                                    }
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
                        Text(viewModel.tiles.count < 2 ? "Add" : "Begin")
                            .font(.headline)
                            .padding(.vertical,8)
                            .frame(maxWidth: .infinity)
                    }
                    .mainActionStyle()
                    // Disable if empty, or 2 tiles already aadded
                    .disabled(viewModel.tiles.count < 2 && viewModel.tileText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    
                    // MARK: Countdown Display (user-facing)
                    if viewModel.phase == .running || viewModel.phase == .finished {
                        Text.styled("\(viewModel.formattedTime)", as: .largeTitle, using: fontTheme, in: palette)
                            .font(.system(size: 80, weight: .bold, design: .monospaced)) // Explicit: fixed-width font
                            .id("countdownTimer") // Use an ID to ensure smooth updates
                            .transition(.opacity) // Smooth transition if it appears/disappears
                        //FIXME: ModifiersFont+Style see the countdown style?
                    }
                    
                    // MARK: - Dynamic Message and Action Area
                    VStack(spacing: 15){
                        // Most constrained state: Session is fully complete, time for recalibration
                        if viewModel.showRecalibrate {
                            Text.styled("Session complete! Ready for recalibration?", as: .header, using: fontTheme, in: palette)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 10)
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
                            
                            // Second most constrained state:
                        } else if viewModel.tiles.count == 2 && viewModel.currentSessionChunk == 1 && viewModel.phase == .finished {
                            
                            // State: First 20-min chunk completed, Overall Session paused
                            Text.styled("Completed the first intended item!", as: .header, using: fontTheme, in: palette)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 5)
                            
                            Text("Ready to focus on your next intention for 20 minutes?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 10)
                            
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
                            
                            
                            Button("End Session Early") {
                                Task {
                                    guard ((try? await viewModel.resetSessionStateForNewStart()) != nil) else {
                                        throw ActiveSessionError.submitFailed
                                    }
                                }
                                debugPrint("EndSession button pressed, User ended session early.")
                                print("Session ended early.")
                            }
                            .buttonStyle(.bordered)
                            .foregroundStyle(.red)
                            .tint(.red)
                            
                        } else if viewModel.phase == .running {
                            
                            // General state: 1st or 2nd tile are active, both countdown OverallSession are running
                            Text("Session in progress...")
                                .foregroundStyle(.gray)
                                .animation(.easeInOut.delay(0.1))
                        } else if viewModel.tiles.count < 2 && (viewModel.tiles.count == 2 && viewModel.phase == .notStarted) {
                            
                            Text("Add your first (or second) intention above")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            // Initial state:0 or 1 tile added only
                            Text("Enter Your Intention and Press `\(viewModel.tiles.count < 2 ? "Add" : "Begin")`")
                                .font(.caption)
                                .foregroundStyle(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }   // End of conditionals and Vstack
                    .padding(.horizontal)   // Padding for entire section
                    .animation(.default, value: viewModel.phase) // Animate phase changes
                    .animation(.default, value: viewModel.tiles.count) // Animate tile count changes
                    
                    Spacer()    // Pushes content away from bottom
                    
                    // MARK: - Fixed-size List: Tile container
                    VStack(spacing: 8) {        // tile spacing
                        ForEach(viewModel.tiles) { tile in
                            Text(tile.text)
                                .font(.body)
                                .padding(10)    // Padding inside each tile
                                .frame(maxWidth: .infinity, alignment: .leading)    // Align text to left
                                .background(palette.primary.opacity(0.1))           // For tile
                                .cornerRadius(8)                                    // For tile
                                .transition(.opacity.animation(.easeIn(duration: 0.3))) // Fade in animation
                        }
                        .padding(.horizonal)    // Padding for the ForEach content
                        
                        // Blank slots and fixed presence for list
                        ForEach(0..<(2 - viewModel.tiles.count), id: \.self) { _ in
                            Text("").hidden()                               // Hidden text, creates space
                                .frame(maxWidth: .infinity, alignment: .leading)    // Align to left
                                .padding(10)
                                .background(palette.background.opacity(0.05))
                                .cornerRadius(10)
                                .overlay(                   // Empty slot dashed border
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(palette.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                                )
                                .padding(.horizontal)
                        }
                    }
                    .frame(height: 120)         // Fixed list height
                    .background(palette.background.opacity(0.8))
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                    
                    Spacer()

                }      //-main VStack end
            
            .background(palette.background.ignoresSafeArea())
            .navigationTitle("")    // Hides default navigation title
            .sheet(isPresented: $viewModel.showRecalibrate){
                RecalibrateV(viewModel: recalibrationVM) // FIXME: NEED recalibrationChoice: selectedChoice?
            }
        }   //-NavigationView end
    }
}

#Preview("Initial State") {
    FocusSessionActiveV()
}
#Preview("After 1st Tile Added") {
    // State: First tile added, ready for second
       let viewModel = FocusSessionVM()
       viewModel.tiles = [TileM(text: "My First Intention")]
       viewModel.tileText = "Second Intention" // Simulate text already typed
       viewModel.canAdd = true // Still can add
       return FocusSessionActiveV(viewModel: viewModel)
}
#Preview("2 Tiles Added - Ready to Begin") {
    // State: Two tiles added, ready to "Begin"
    let viewModel = FocusSessionVM()
    viewModel.tiles = [TileM(text: "Intention 1"), TileM(text: "Intention 2")]
    viewModel.canAdd = false // Cannot add more
    viewModel.phase = .notStarted // No countdown running yet
    return FocusSessionActiveV(viewModel: viewModel)
}

#Preview("1st Chunk Running") {
    // State: Countdown for first chunk is running
    let viewModel = FocusSessionVM()
    viewModel.tiles = [TileM(text: "Intention 1"), TileM(text: "Intention 2")]
    viewModel.canAdd = false
    viewModel.phase = .running
    viewModel.countdownRemaining = 600 // 10 minutes left
    viewModel.currentSessionChunk = 0 // Still on the first chunk
    return FocusSessionActiveV(viewModel: viewModel)
}

#Preview("1st Chunk Completed - Prompt for 2nd") {
    // State: First chunk finished, ready for second
    let viewModel = FocusSessionVM()
    viewModel.tiles = [TileM(text: "Intention 1"), TileM(text: "Intention 2")]
    viewModel.canAdd = false
    viewModel.phase = .finished // First chunk completed
    viewModel.countdownRemaining = 0 // Timer hit zero
    viewModel.currentSessionChunk = 1 // Moved to next chunk
    return FocusSessionActiveV(viewModel: viewModel)
}

#Preview("2nd Chunk Running"){
    // State: Countdown for second chunk is running
    let viewModel = FocusSessionVM()
    viewModel.tiles = [TileM(text: "Intention 1"), TileM(text: "Intention 2")]
    viewModel.canAdd = false
    viewModel.phase = .running
    viewModel.countdownRemaining = 300 // 5 minutes left
    viewModel.currentSessionChunk = 1 // Second chunk in progress
    return FocusSessionActiveV(viewModel: viewModel)
}

#Preview("Session Complete - Recalibrate Prompt"){
    // State: Session complete, show recalibration modal prompt
    let viewModel = FocusSessionVM()
    viewModel.tiles = [TileM(text: "Intention 1"), TileM(text: "Intention 2")]
    viewModel.canAdd = false
    viewModel.phase = .finished // Second chunk completed
    viewModel.countdownRemaining = 0
    viewModel.currentSessionChunk = 2 // Both chunks completed
    viewModel.showRecalibrate = true // Trigger recalibration modal
    return FocusSessionActiveV(viewModel: viewModel)
}

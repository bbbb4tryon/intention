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
│   │   └── HistoryV.swift                 // view HistoryV of completed todos
│   │   └── HistoryVM.swift
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
    @EnvironmentObject var theme: ThemeManager
    @EnvironmentObject var userService: UserService
    @EnvironmentObject var statsVM: StatsVM
    @EnvironmentObject var membershipVM: MembershipVM
    @Environment(\.dismiss) var dismiss
    
    @ObservedObject var viewModel: FocusSessionVM
    @ObservedObject var recalibrationVM: RecalibrationVM
    
    @State private var showMembershipSheet = false
    
    var body: some View {
        // Get current palette for the appropriate sceen
        let palette = theme.palette(for: .homeActiveIntentions)
        let progress = Double(viewModel.countdownRemaining) / 1200.0
        
        NavigationLink(destination: RecalibrateV(viewModel: recalibrationVM), isActive: $viewModel.showRecalibrate) { EmptyView()
        }.hidden()
        
        //        NavigationView {
        VStack(spacing: 20){
            
            StatsSummaryBar(palette: palette)
            
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
                    Text(viewModel.tiles.count < 2 ? "Add" : "Begin")
                        .font(.headline)
                        .padding(.vertical,8)
                        .frame(maxWidth: .infinity)
                }
                .mainActionStyle(screen: .homeActiveIntentions)
                .environmentObject(theme)
                // Disable if empty, or 2 tiles already aadded
                .disabled(viewModel.tiles.count < 2 && viewModel.tileText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
            }
            
            
            // MARK: Countdown Display (user-facing)
            if viewModel.phase == .running || viewModel.phase == .finished {
                ZStack {
                    Circle()
                        .fill(palette.background.opacity(0.2))
                        .frame(width: 200, height: 200)
                    
                    UnwindingPieShape(progress: progress)
                        .fill(palette.primary)
                        .frame(width: 200, height: 200)
                    
                    Text("\(viewModel.formattedTime)")
                        .font(.system(size: 48, weight: .bold, design: .monospaced)) // Explicit: fixed-width font
                        .id("countdownTimer") // Use an ID to ensure smooth updates
                        .transition(.opacity) // Smooth transition if it appears/disappears
                        .foregroundStyle(palette.text)
                }
                .animation(.easeInOut(duration: 0.2), value: progress)
            }
            
            
            // MARK: - Dynamic Message and Action Area
            DynamicMessageAndActionArea(
                viewModel: viewModel,
                fontTheme: theme.fontTheme, // passing in fontTheme property
                palette: theme.palette(for: .homeActiveIntentions),
                onRecalibrateNow: {
                    viewModel.showRecalibrate = true
                })
            
            Spacer()    // Pushes content away from bottom
            
            
            // MARK: - Fixed-size List: Tile container
            VStack(spacing: 8) {        // tile spacing
                ForEach(slotData.indices, id: \.self) { index in
                    TileSlotView(
                        tileText: slotData[index],
                    )
                }
                .padding(.horizontal)    // Padding for the ForEach content
            }   // -VStack, tile container end
            .frame(height: 140)         // Fixed list height - (e.g., 2 tiles * ~50-60pt height each)
            .background(palette.background.opacity(0.8))
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding(.horizontal)       // Horizonal padding for whole list
            
            Spacer()
        }      // -VStack, primary end
        
        .background(palette.background.ignoresSafeArea())
        //            .navigationTitle("")    // Hides default navigation title
        
        .sheet(isPresented: $membershipVM.shouldPrompt) {
            VStack(spacing: 20) {
                Text("After two completed sessions, consider a membership for unlimited sessions and extra features.")
                    .multilineTextAlignment(.center)
                
                if statsVM.isMember {
                    Text("You area member ✅")
                } else {
                    Button("Buy Membership"){
                        Task { await statsVM.purchaseMembership }
                    }
                    
                    Button("Restore Purchases") {
                        Task { await statsVM.restoreMembership  }
                    }
                    
                    Divider()
                    
                    // Token flow
                    
                    Button("Enter Membership Code"){
                        //otp for entering the code
                    }
                    
                    if !AppEnvironment.isAppStoreReviewing {
                        Button("Visit Website") {
                            if let url = URL(string: "https://www.argonnesoftware.com/cart/") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .mainActionStyle(screen: .homeActiveIntentions)
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $viewModel.showRecalibrate){
            RecalibrateV(viewModel: recalibrationVM) // FIXME: NEED recalibrationChoice: selectedChoice?
        }
        //        }   // -NavigationView end
        
    }
    // MARK: - [String?, String?] ->
    //  Extracted computed property, easier for compliler to parse
    private var slotData: [String?] {
        var data = [String?]()
        for t in 0..<2 {
            if t < viewModel.tiles.count {
                data.append(viewModel.tiles[t].text)
            } else {
                data.append(nil)
            }
        }
        return data
    }
}


#Preview("Initial State") {
    FocusSessionActiveV(
        viewModel: FocusSessionVM(previewMode: true),
        recalibrationVM: RecalibrationVM()
    )
//        .environmentObject(stats)
//        .environmentObject(userService)
//        .environmentObject(theme)
        .previewTheme()
}
//#Preview("After 1st Tile Added") {
//    // State: First tile added, ready for second
//    let focus = FocusSessionVM()
//        focus.tiles = [TileM(text: "My First Intention")]
//        focus.tileText = "Second Intention"
//        focus.canAdd = true
//    
//    let recal = RecalibrationVM()
//    let stats = StatsVM()
//    let userService = UserService()
//    let theme = ThemeManager()
//    
//    return FocusSessionActiveV(viewModel: focus, recalibrationVM: recal)
//            .environmentObject(stats)
//            .environmentObject(userService)
//            .environmentObject(theme)
//            .previewTheme()
//}
//#Preview("2 Tiles Added - Ready to Begin") {
//    let focus = FocusSessionVM()
//       focus.tiles = [TileM(text: "Intention 1"), TileM(text: "Intention 2")]
//       focus.canAdd = false
//       focus.phase = .notStarted
//    
//    let recal = RecalibrationVM()
//    let stats = StatsVM()
//    let userService = UserService()
//    let theme = ThemeManager()
//   
//    return FocusSessionActiveV(viewModel: focus, recalibrationVM: recal)
//            .environmentObject(stats)
//            .environmentObject(userService)
//            .environmentObject(theme)
//            .previewTheme()
//}
//
//#Preview("1st Chunk Running") {
//    // State: Countdown for first chunk is running
//    let focus = FocusSessionVM()
//       focus.tiles = [TileM(text: "Intention 1"), TileM(text: "Intention 2")]
//       focus.canAdd = false
//       focus.phase = .running
//       focus.countdownRemaining = 600
//       focus.currentSessionChunk = 0
//
//       let recal = RecalibrationVM()
//       let stats = StatsVM()
//       let userService = UserService()
//       let theme = ThemeManager()
//
//       return FocusSessionActiveV(viewModel: focus, recalibrationVM: recal)
//           .environmentObject(stats)
//           .environmentObject(userService)
//           .environmentObject(theme)
//           .previewTheme()
//}
//
//#Preview("1st Chunk Completed - Prompt for 2nd") {
//    let focus = FocusSessionVM()
//       focus.tiles = [TileM(text: "Intention 1"), TileM(text: "Intention 2")]
//       focus.canAdd = false
//       focus.phase = .finished
//       focus.countdownRemaining = 0
//       focus.currentSessionChunk = 1
//
//       let recal = RecalibrationVM()
//       let stats = StatsVM()
//       let userService = UserService()
//       let theme = ThemeManager()
//
//       return FocusSessionActiveV(viewModel: focus, recalibrationVM: recal)
//           .environmentObject(stats)
//           .environmentObject(userService)
//           .environmentObject(theme)
//           .previewTheme()
//}
//
//#Preview("2nd Chunk Running"){
//    let focus = FocusSessionVM()
//        focus.tiles = [TileM(text: "Intention 1"), TileM(text: "Intention 2")]
//        focus.canAdd = false
//        focus.phase = .running
//        focus.countdownRemaining = 300
//        focus.currentSessionChunk = 1
//
//        let recal = RecalibrationVM()
//        let stats = StatsVM()
//        let userService = UserService()
//        let theme = ThemeManager()
//
//        return FocusSessionActiveV(viewModel: focus, recalibrationVM: recal)
//            .environmentObject(stats)
//            .environmentObject(userService)
//            .environmentObject(theme)
//            .previewTheme()
//}
//
//#Preview("Session Complete - Recalibrate Prompt"){
//    let focus = FocusSessionVM()
//        focus.tiles = [TileM(text: "Intention 1"), TileM(text: "Intention 2")]
//        focus.canAdd = false
//        focus.phase = .finished
//        focus.countdownRemaining = 0
//        focus.currentSessionChunk = 2
//        focus.showRecalibrate = true
//
//        let recal = RecalibrationVM()
//        let stats = StatsVM()
//        let userService = UserService()
//        let theme = ThemeManager()
//
//        return FocusSessionActiveV(viewModel: focus, recalibrationVM: recal)
//            .environmentObject(stats)
//            .environmentObject(userService)
//            .environmentObject(theme)
//            .previewTheme()
//}

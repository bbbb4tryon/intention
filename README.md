no-glow logo:
Settings screen bottom logo

Category icons

In-app badges

HistoryV

Buttons / lists / headers

Low-contrast UI environments

soft logo:
AppIcon.appiconset

RuntimeAppIcon.imageset (if you keep it separate)

Marketing images

TestFlight icon previews

Launchscreen-logo (with or without a little ground shadow)

#  Style Guide

**Rule 1 – *File layout*:**
State & theme at the top → pure helpers above body → body as story → helper subviews and small types below.

1. **Stored properties / dependencies at the top**
    [*] `@EnvironmentObject`, `@ObservedObject`, `@State`
    [*] Theme hooks (`screen`, `p`, `T`)
    [*] Local color constants / layout constants
2. **Computed helpers and small functions**
    [*] Cheap booleans (`canAddCategory`, `hasGeneralTiles`)
    [*] Derived views (`historyTitleText`, `separator`, `renameCategorySheet`)
    [*] Tiny side-effect functions (`finalizeHistoryIfNeededOnDisappear()`)
3. **`var body: some View` as the “story spine”**
    [*] Reads like prose: *list → toasts → overlays → sheet → alert*
4. **Helper views / nested types at the bottom**
    [*] structs `CategoryCard`, `RenameCategoryV`, `HistoryToasts`
    [*] Little utility extensions (`Array.only`, `String.ifEmpty`)

**Rule 2 – *Computed property*:**
Use `private *var* …` when it’s:
    [*] Pure (no side effects)
    [*] Has no parameters
    [*] Just derives something from existing state (Bool, Text, small View, etc.)
    [*] Return the *same result every time* for the same underlying state
        [-] they sit above `body:` they’re “descriptive ingredients” the body uses


**Rule 3 – *Function*:**
Use `private *func* … ` when:
    [*] You need arguments (`slot`, `tile`)
    [*] Result presents side effects (inputs, outputs that go somewhere, VM calls, logging)
    [*] “does a thing” not “describes a value”
    
**Rule 4 - *Stored Constant*:**
Use `private let … `when:
    [*] The value never changes during the lifetime of the view instance
    [*] It doesn’t depend on changing state / env
    [*] It’s just a design token (colors, sizes, enums)

Truly constant per view type:
    [-] private let screen: ScreenName = .history
    [-] Your local color constants (textSecondary, colorBorder, dividerRects)
    [-] Layout primitives (padding units, corner radii, etc.)

**Rule 5 – *Nested view structs*:**
Use a nested `private struct …: View` when:
    [*] You need a reusable renderable piece that takes parameters
    [*] It would make body noticeably clearer if factored out
    [*] It has its own little layout story
[-] Keep them below body so the main view reads like an API: “top-level behavior → details further down”.

**Rule 6 - *side effects*:**
    [*] If something changes the world (saves, logs, sends messages, triggers actors), it should be a `**function**`
    [*] That function should be called from an explicit place in body (e.g. .onDisappear { finalizeHistoryIfNeededOnDisappear() }).


**Property vs function vs “subview var” – decision tree**
1. **Does it mutate state, call the VM, or do I/O?**
    [*] ➜ Yes → `private func` (*never* a computed property)
2. **Does it need parameters?**
    [*] ➜ Yes → `private func foo(param:)` -> X or `private struct Foo: View { init(param: …) }`
3. **Is it just a derived bit of view or data, with no side effects, no params?**
    [*] ➜ Yes → `private var foo: Type { … }`
4. **Is it a substantial bit of UI used in multiple places or with several parameters?**
    [*] ➜ Yes → `private struct FooView: View { … }` below `var body: some View {...}` *at the bottom of the file*
5. **Is it a design token?**
    [*] ➜ Yes → `private let` (colors, screen name, padding, etc.) constant above `var body: some View {...}` 


**Why “computed helpers above body” works so well**
Pure helpers above body allows:
    [*] the compiler to see all derivations before it encounters the big body tree.
    [*] the `body` to be read and referenced easily
    [*] *Example:*
    ScrollView → Page → Category list → HistoryToasts → overlay → sheet → alert

    [*] Anyone reading the file can scan:
    [-] What state does this view own?
    [-] Which little facts/computed bits does it know?
    [-] What story does body tell?
    [-] How are the supporting views implemented below?
    

    
/// What this thing is (2-15 words, active voice).
/// - Why it exists (2-10 words, active voice) OR, if descriptively evident, what calls it why and when (2-15 words, active voice)
/// - If not present in previous bullet, define Parameters and "the what" if ambiguous
/// - Notes: Scope/ownership/side-effects (2-15 words per, active voice).
/// - don't bother listing Throws
@MainActor
final class ExampleVM {

    /// Describes what the property represents (single source of truth / cache / config).
    @Published var someState: Bool = false

    /// Do X. Throws Y when Z.
    /// - Parameter input: What the caller supplies.
    /// - Throws: SpecificError.case when <condition>.
    func doX(with input: String) async throws {
        // 1) Validate input
        // 2) Talk to actor/service
        // 3) Update state + persist
        // 4) Notify UI (haptics/toast)
    }
}


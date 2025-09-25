#  Style Guide

/// What this thing is (1 short sentence).
/// - Why it exists (one short clause if needed).
/// - Notes: Scope/ownership/side-effects (keep it brief).
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


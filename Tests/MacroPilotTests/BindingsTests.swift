import Testing
@testable import MacroPilot

@Test func allNeutralKeysHaveAnAction() {
  #expect(DefaultBindings.all.count == 9)
  #expect(DefaultBindings.all.allSatisfy { DefaultBindings.action(for: $0.keyCode) != nil })
}

@Test func actionSafetyMatchesIntent() {
  #expect(MacroAction.send.requiresConfirmation)
  #expect(MacroAction.newTask.requiresConfirmation)
  #expect(!MacroAction.stop.requiresConfirmation)
}

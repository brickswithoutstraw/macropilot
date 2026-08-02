import AppKit
import ApplicationServices

@MainActor
final class ActionController {
  var onUpdate: ((String) -> Void)?
  private var lastStatus = "MacroPilot ready"
  private var pendingConfirmation: (action: MacroAction, expires: Date)?
  private var profileIndex = 0
  private let profiles = ["AI Workbench", "General", "Media"]

  func perform(_ action: MacroAction) {
    if action.requiresConfirmation && !isConfirmed(action) {
      pendingConfirmation = (action, Date().addingTimeInterval(3))
      announce("Press \(action.title) again within 3 seconds to confirm")
      return
    }
    pendingConfirmation = nil

    switch action {
    case .summon:
      activateCodexOrMacroPilot()
    case .voice:
      announce("Voice is ready for a configurable dictation shortcut")
    case .captureContext:
      captureContext()
    case .stop:
      postKey(keyCode: 53, modifiers: [])
      announce("Stop: sent Escape to the active app")
    case .send:
      postKey(keyCode: 36, modifiers: [.maskCommand])
      announce("Send: sent Command-Return to the active app")
    case .newTask:
      postKey(keyCode: 45, modifiers: [.maskCommand])
      announce("New Task: sent Command-N to the active app")
    case .previousProfile:
      profileIndex = (profileIndex + profiles.count - 1) % profiles.count
      announce("Profile: \(profiles[profileIndex])")
    case .nextProfile, .cycleProfile:
      profileIndex = (profileIndex + 1) % profiles.count
      announce("Profile: \(profiles[profileIndex])")
    }
  }

  func announce(_ text: String) {
    lastStatus = text
    onUpdate?(text)
    NSLog("MacroPilot: %@", text)
  }

  func presentStatus() {
    let alert = NSAlert()
    alert.messageText = "MacroPilot"
    alert.informativeText = lastStatus
    alert.addButton(withTitle: "OK")
    alert.runModal()
  }

  private func isConfirmed(_ action: MacroAction) -> Bool {
    guard let pendingConfirmation else { return false }
    return pendingConfirmation.action == action && pendingConfirmation.expires > Date()
  }

  private func activateCodexOrMacroPilot() {
    let candidates = NSWorkspace.shared.runningApplications.filter {
      $0.localizedName?.localizedCaseInsensitiveContains("Codex") == true
    }
    if let codex = candidates.first {
      codex.activate(options: [])
      announce("Codex brought forward")
    } else {
      NSApp.activate(ignoringOtherApps: true)
      announce("MacroPilot brought forward — Codex is not running")
    }
  }

  private func captureContext() {
    let text = NSPasteboard.general.string(forType: .string) ?? ""
    let message = text.isEmpty ? "No text found on the clipboard" : "Captured \(text.count) clipboard characters"
    announce(message)
  }

  private func postKey(keyCode: CGKeyCode, modifiers: CGEventFlags) {
    guard AXIsProcessTrusted() else {
      announce("Accessibility permission is required before MacroPilot can send keys")
      return
    }
    let source = CGEventSource(stateID: .hidSystemState)
    let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
    let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
    down?.flags = modifiers
    up?.flags = modifiers
    down?.post(tap: .cghidEventTap)
    up?.post(tap: .cghidEventTap)
  }
}

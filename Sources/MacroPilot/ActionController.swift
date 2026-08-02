import AppKit
import ApplicationServices

@MainActor
final class ActionController {
  var onUpdate: ((String) -> Void)?
  private var lastStatus = "MacroPilot ready"
  private var pendingConfirmation: (action: MacroAction, expires: Date)?
  private var profileIndex = 0
  private var chatBarReadyUntil: Date?
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
      openChatGPTChatBar()
    case .voice:
      announce("Voice key reached MacroPilot. Set ChatGPT Dictation Toggle to Control-Option-B.")
    case .captureContext:
      shareActiveWindowWithChatGPT()
    case .stop:
      if postKey(keyCode: 47, modifiers: [.maskCommand]) {
        announce("Stop: sent Command-Period to ChatGPT")
      }
    case .send:
      guard (chatBarReadyUntil ?? .distantPast) > Date() else {
        announce("Open the ChatGPT Chat Bar first, then use Send")
        return
      }
      if postKey(keyCode: 36, modifiers: []) {
        announce("Send: sent Return to the focused ChatGPT prompt")
      }
    case .newTask:
      openChatGPTChatBar()
      announce("New Chat: requested the ChatGPT Chat Bar")
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

  func presentVoiceSetup() {
    let alert = NSAlert()
    alert.messageText = "MacroPilot Voice"
    alert.informativeText = "1. In ChatGPT Settings → Dictation, set Toggle dictation hotkey to Control-Option-B.\n\n2. Grant ChatGPT Microphone permission.\n\n3. Press the pad’s top-middle key. A crosshair means Dictation is ready: click the text field where words should go, then speak. Press the same key again to stop.\n\nWhen ChatGPT owns the shortcut, MacroPilot will not log the Voice key—that is expected."
    alert.addButton(withTitle: "Got it")
    alert.runModal()
  }

  func setLED(mode: Int, name: String) {
    guard let tool = Bundle.main.url(forResource: "ch57x-keyboard-tool", withExtension: nil) else {
      announce("LED helper is unavailable in this development build")
      return
    }
    let process = Process()
    process.executableURL = tool
    process.arguments = ["--product-id", "0x8890", "led", String(mode)]
    do {
      try process.run()
      announce("LED mode requested: \(name)")
    } catch {
      announce("Could not set LED mode: \(error.localizedDescription)")
    }
  }

  private func isConfirmed(_ action: MacroAction) -> Bool {
    guard let pendingConfirmation else { return false }
    return pendingConfirmation.action == action && pendingConfirmation.expires > Date()
  }

  private func openChatGPTChatBar() {
    // ChatGPT for macOS uses Option-Space as its configurable Chat Bar shortcut.
    if postKey(keyCode: 49, modifiers: [.maskAlternate]) {
      chatBarReadyUntil = Date().addingTimeInterval(15)
      announce("ChatGPT Chat Bar requested")
    }
  }

  private func shareActiveWindowWithChatGPT() {
    // ChatGPT's standard shortcut for sharing the active window as context.
    if postKey(keyCode: 19, modifiers: [.maskCommand, .maskShift]) {
      announce("Context: requested active-window sharing with ChatGPT")
    }
  }

  @discardableResult
  private func postKey(keyCode: CGKeyCode, modifiers: CGEventFlags) -> Bool {
    guard AXIsProcessTrusted() else {
      announce("Accessibility permission is required before MacroPilot can send keys")
      return false
    }
    let source = CGEventSource(stateID: .hidSystemState)
    let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
    let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
    down?.flags = modifiers
    up?.flags = modifiers
    down?.post(tap: .cghidEventTap)
    up?.post(tap: .cghidEventTap)
    return true
  }
}

import AppKit
import Carbon.HIToolbox

enum MacroAction: String, CaseIterable, Identifiable {
  case summon
  case voice
  case captureContext
  case stop
  case send
  case newTask
  case previousProfile
  case nextProfile
  case cycleProfile

  var id: String { rawValue }

  var title: String {
    switch self {
    case .summon: "Summon MacroPilot"
    case .voice: "Voice"
    case .captureContext: "Capture Context"
    case .stop: "Stop"
    case .send: "Send"
    case .newTask: "New Task"
    case .previousProfile: "Previous Profile"
    case .nextProfile: "Next Profile"
    case .cycleProfile: "Cycle Profile"
    }
  }

  var requiresConfirmation: Bool {
    self == .send || self == .newTask
  }
}

struct KeyBinding: Identifiable, Equatable {
  let keyCode: UInt16
  let label: String
  let action: MacroAction
  var id: UInt16 { keyCode }
}

enum DefaultBindings {
  static let all: [KeyBinding] = [
    .init(keyCode: UInt16(kVK_ANSI_A), label: "⌃⌥A", action: .summon),
    .init(keyCode: UInt16(kVK_ANSI_B), label: "⌃⌥B", action: .voice),
    .init(keyCode: UInt16(kVK_ANSI_C), label: "⌃⌥C", action: .captureContext),
    .init(keyCode: UInt16(kVK_ANSI_D), label: "⌃⌥D", action: .stop),
    .init(keyCode: UInt16(kVK_ANSI_E), label: "⌃⌥E", action: .send),
    .init(keyCode: UInt16(kVK_ANSI_F), label: "⌃⌥F", action: .newTask),
    .init(keyCode: UInt16(kVK_ANSI_G), label: "⌃⌥G", action: .previousProfile),
    .init(keyCode: UInt16(kVK_ANSI_I), label: "⌃⌥I", action: .nextProfile),
    .init(keyCode: UInt16(kVK_ANSI_H), label: "⌃⌥H", action: .cycleProfile)
  ]

  static func action(for keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> MacroAction? {
    guard modifiers.contains([.control, .option]) else { return nil }
    return all.first(where: { $0.keyCode == keyCode })?.action
  }
}

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
    .init(keyCode: UInt16(kVK_F13), label: "F13", action: .summon),
    .init(keyCode: UInt16(kVK_F14), label: "F14", action: .voice),
    .init(keyCode: UInt16(kVK_F15), label: "F15", action: .captureContext),
    .init(keyCode: UInt16(kVK_F16), label: "F16", action: .stop),
    .init(keyCode: UInt16(kVK_F17), label: "F17", action: .send),
    .init(keyCode: UInt16(kVK_F18), label: "F18", action: .newTask),
    .init(keyCode: UInt16(kVK_F19), label: "F19", action: .previousProfile),
    .init(keyCode: UInt16(kVK_F20), label: "F20", action: .nextProfile),
    // Carbon does not export kVK_F21, but macOS assigns it virtual key 96.
    .init(keyCode: 96, label: "F21", action: .cycleProfile)
  ]

  static func action(for keyCode: UInt16) -> MacroAction? {
    all.first(where: { $0.keyCode == keyCode })?.action
  }
}

import AppKit

@MainActor
final class SetupWizard: NSWindowController {
  private let status = NSTextField(wrappingLabelWithString: "Connect the wired six-key + one-knob 1189:8890 pad, then choose a safe action below.")

  convenience init() {
    let content = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 330))
    let window = NSWindow(contentRect: content.bounds,
                          styleMask: [.titled, .closable],
                          backing: .buffered,
                          defer: false)
    window.title = "MacroPilot Pad Setup"
    window.center()
    window.contentView = content
    self.init(window: window)

    let title = NSTextField(labelWithString: "Set up your MacroPilot pad")
    title.font = .systemFont(ofSize: 22, weight: .bold)
    title.frame = NSRect(x: 28, y: 275, width: 444, height: 30)
    content.addSubview(title)

    let note = NSTextField(wrappingLabelWithString: "Reference hardware: wired 3×2 mechanical pad with one knob, USB ID 1189:8890. This beta never changes a key map without an explicit button press.")
    note.textColor = .secondaryLabelColor
    note.frame = NSRect(x: 28, y: 220, width: 444, height: 46)
    content.addSubview(note)

    let calibration = Self.button("1. Test physical key order", action: #selector(startCalibration))
    calibration.frame = NSRect(x: 28, y: 168, width: 215, height: 32)
    content.addSubview(calibration)

    let apply = Self.button("2. Apply verified layout", action: #selector(applyLayout))
    apply.frame = NSRect(x: 257, y: 168, width: 215, height: 32)
    content.addSubview(apply)

    let off = Self.button("LEDs off", action: #selector(ledOff))
    off.frame = NSRect(x: 28, y: 120, width: 135, height: 30)
    content.addSubview(off)

    let steady = Self.button("Steady red", action: #selector(ledSteady))
    steady.frame = NSRect(x: 182, y: 120, width: 135, height: 30)
    content.addSubview(steady)

    let reactive = Self.button("Reactive LEDs", action: #selector(ledReactive))
    reactive.frame = NSRect(x: 336, y: 120, width: 136, height: 30)
    content.addSubview(reactive)

    status.frame = NSRect(x: 28, y: 32, width: 444, height: 70)
    status.textColor = .secondaryLabelColor
    content.addSubview(status)
    content.subviews.compactMap { $0 as? NSButton }.forEach { $0.target = self }
  }

  private static func button(_ title: String, action: Selector) -> NSButton {
    let button = NSButton(title: title, target: nil, action: action)
    button.bezelStyle = .rounded
    button.target = nil
    return button
  }

  @objc private func startCalibration() {
    runMapper("--apply-calibration-layout", success: "Calibration letters are active. In a text field, press the six keys top row then bottom row, then turn-left / press / turn-right. Record the letters before applying the verified layout.")
  }

  @objc private func applyLayout() {
    runMapper("--apply-macropilot-boot-layout", success: "Verified Control-Option layout applied to startup layer. Restart MacroPilot, then use the pad normally.")
  }

  @objc private func ledOff() { runLED(0, name: "LEDs off") }
  @objc private func ledSteady() { runLED(1, name: "Steady red LEDs enabled") }
  @objc private func ledReactive() { runLED(2, name: "Reactive LEDs enabled") }

  private func runMapper(_ argument: String, success: String) {
    status.stringValue = "Writing pad configuration…"
    DeviceTool.run(named: "macropilot-sikai-map", arguments: [argument]) { [weak self] result in
      self?.status.stringValue = result.success ? success : result.message
    }
  }

  private func runLED(_ mode: Int, name: String) {
    status.stringValue = "Changing LED mode…"
    DeviceTool.run(named: "ch57x-keyboard-tool", arguments: ["--product-id", "0x8890", "led", String(mode)]) { [weak self] result in
      self?.status.stringValue = result.success ? name : result.message
    }
  }
}

@MainActor
enum DeviceTool {
  struct Result { let success: Bool; let message: String }

  static func run(named name: String, arguments: [String], completion: @escaping @MainActor (Result) -> Void) {
    guard let executable = Bundle.main.url(forResource: name, withExtension: nil) else {
      completion(.init(success: false, message: "This app build does not include \(name). Rebuild MacroPilot from its source folder."))
      return
    }
    let process = Process()
    process.executableURL = executable
    process.arguments = arguments
    process.terminationHandler = { process in
      DispatchQueue.main.async {
        completion(.init(success: process.terminationStatus == 0,
                         message: process.terminationStatus == 0 ? "Done." : "The pad did not accept the command. Check the USB cable and try again."))
      }
    }
    do {
      try process.run()
    } catch {
      completion(.init(success: false, message: "Could not start the device helper: \(error.localizedDescription)"))
    }
  }
}

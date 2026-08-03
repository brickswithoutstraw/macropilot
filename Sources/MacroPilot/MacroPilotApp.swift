import AppKit
import ApplicationServices

@main
@MainActor
final class MacroPilotApp: NSObject, NSApplicationDelegate {
  private let controller = ActionController()
  private var statusItem: NSStatusItem!
  private var eventMonitor: Any?
  private var setupWizard: SetupWizard?

  static func main() {
    let app = NSApplication.shared
    let delegate = MacroPilotApp()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
  }

  func applicationDidFinishLaunching(_ notification: Notification) {
    installStatusItem()
    installKeyboardMonitor()
    controller.onUpdate = { [weak self] text in
      DispatchQueue.main.async { self?.statusItem.button?.toolTip = text }
    }
    controller.announce("MacroPilot ready — listening for Control-Option-A through I")
  }

  func applicationWillTerminate(_ notification: Notification) {
    if let eventMonitor { NSEvent.removeMonitor(eventMonitor) }
  }

  private func installStatusItem() {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    if let image = Bundle.main.image(forResource: "MenuBarIcon") {
      image.isTemplate = true
      image.size = NSSize(width: 18, height: 18)
      statusItem.button?.image = image
      statusItem.button?.imagePosition = .imageOnly
    } else {
      statusItem.button?.title = "MP"
    }
    statusItem.button?.toolTip = "MacroPilot starting"

    let menu = NSMenu()
    menu.addItem(NSMenuItem(title: "MacroPilot", action: nil, keyEquivalent: ""))
    menu.addItem(.separator())
    menu.addItem(NSMenuItem(title: "Voice Setup…", action: #selector(showVoiceSetup), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Set Up Pad…", action: #selector(showPadSetup), keyEquivalent: ""))
    menu.addItem(NSMenuItem(title: "Check Accessibility Permission", action: #selector(requestAccessibility), keyEquivalent: ""))
    let leds = NSMenuItem(title: "LEDs", action: nil, keyEquivalent: "")
    let ledMenu = NSMenu()
    ledMenu.addItem(NSMenuItem(title: "Off", action: #selector(ledOff), keyEquivalent: ""))
    ledMenu.addItem(NSMenuItem(title: "Steady red", action: #selector(ledSteady), keyEquivalent: ""))
    ledMenu.addItem(NSMenuItem(title: "Reactive", action: #selector(ledReactive), keyEquivalent: ""))
    ledMenu.items.forEach { $0.target = self }
    leds.submenu = ledMenu
    menu.addItem(leds)
    menu.addItem(NSMenuItem(title: "Show Last Action", action: #selector(showLastAction), keyEquivalent: ""))
    menu.addItem(.separator())
    menu.addItem(NSMenuItem(title: "Quit MacroPilot", action: #selector(quit), keyEquivalent: "q"))
    menu.items.forEach { $0.target = self }
    statusItem.menu = menu
  }

  private func installKeyboardMonitor() {
    eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
      guard let action = DefaultBindings.action(for: event.keyCode, modifiers: event.modifierFlags) else { return }
      DispatchQueue.main.async { self?.controller.perform(action) }
    }
  }

  @objc private func requestAccessibility() {
    let promptKey = "AXTrustedCheckOptionPrompt" as CFString
    let options = [promptKey: true] as CFDictionary
    let trusted = AXIsProcessTrustedWithOptions(options)
    controller.announce(trusted ? "Accessibility permission is enabled" : "Approve MacroPilot in System Settings, then return here")
  }

  @objc private func showLastAction() { controller.presentStatus() }
  @objc private func showVoiceSetup() { controller.presentVoiceSetup() }
  @objc private func showPadSetup() {
    let wizard = SetupWizard()
    setupWizard = wizard
    wizard.showWindow(nil)
    wizard.window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
  @objc private func ledOff() { controller.setLED(mode: 0, name: "off") }
  @objc private func ledSteady() { controller.setLED(mode: 1, name: "steady red") }
  @objc private func ledReactive() { controller.setLED(mode: 2, name: "reactive") }
  @objc private func quit() { NSApp.terminate(nil) }
}

import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var flutterViewController: FlutterViewController?

  override func awakeFromNib() {
    let controller = FlutterViewController()
    flutterViewController = controller
    let windowFrame = self.frame
    self.contentViewController = controller
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: controller)
    setupFocusChannel(controller)

    super.awakeFromNib()
  }

  override func becomeKey() {
    super.becomeKey()
    DispatchQueue.main.async { [weak self] in
      guard let self, let view = self.flutterViewController?.view else { return }
      if self.firstResponder !== view { self.makeFirstResponder(view) }
    }
  }

  private func setupFocusChannel(_ controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "clio/native_focus",
      binaryMessenger: controller.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "reclaimKeyboard" {
        if let view = self?.flutterViewController?.view {
          self?.makeFirstResponder(view)
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

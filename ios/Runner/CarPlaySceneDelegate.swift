import CarPlay
import Flutter
import UIKit

/// CarPlay audio app: lists the same library tree as Android Auto.
///
/// The tree comes from the Dart side over the `melody/carplay` channel
/// (`children` returns items, `play` starts one). CarPlay only shows this
/// scene when the app has Apple's CarPlay audio entitlement; see
/// docs/IOS.md.
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  private var interfaceController: CPInterfaceController?

  private var channel: FlutterMethodChannel? {
    guard let messenger = AppDelegate.messenger else { return nil }
    return FlutterMethodChannel(name: "melody/carplay", binaryMessenger: messenger)
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
  ) {
    self.interfaceController = interfaceController
    let root = CPListTemplate(title: "Melody", sections: [])
    interfaceController.setRootTemplate(root, animated: false, completion: nil)
    load(id: "root", into: root)
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnectInterfaceController interfaceController: CPInterfaceController
  ) {
    self.interfaceController = nil
  }

  /// Asks Dart for the entries below [id] and shows them in [template].
  private func load(id: String, into template: CPListTemplate) {
    guard let channel = channel else {
      // The app was not opened on the phone yet: nothing to browse.
      template.updateSections([])
      return
    }
    channel.invokeMethod("children", arguments: id) { [weak self] result in
      guard let self = self, let entries = result as? [[String: Any]] else { return }
      let items: [CPListItem] = entries.map { entry in
        let item = CPListItem(
          text: entry["title"] as? String,
          detailText: entry["subtitle"] as? String
        )
        let childId = entry["id"] as? String ?? ""
        let playable = entry["playable"] as? Bool ?? false
        if !playable { item.accessoryType = .disclosureIndicator }
        item.handler = { [weak self] _, completion in
          self?.select(id: childId, title: entry["title"] as? String, playable: playable)
          completion()
        }
        return item
      }
      template.updateSections([CPListSection(items: items)])
    }
  }

  private func select(id: String, title: String?, playable: Bool) {
    if playable {
      channel?.invokeMethod("play", arguments: id)
      interfaceController?.pushTemplate(
        CPNowPlayingTemplate.shared, animated: true, completion: nil)
    } else {
      let list = CPListTemplate(title: title, sections: [])
      interfaceController?.pushTemplate(list, animated: true, completion: nil)
      load(id: id, into: list)
    }
  }
}

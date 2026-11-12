import AVKit
import Flutter
import UIKit

/// Native AirPlay route picker shown inside the Flutter UI
/// (view type `melody/airplay`).
final class AirPlayButtonFactory: NSObject, FlutterPlatformViewFactory {
  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    AirPlayButton(frame: frame, arguments: args)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

private final class AirPlayButton: NSObject, FlutterPlatformView {
  private let picker: AVRoutePickerView

  init(frame: CGRect, arguments: Any?) {
    picker = AVRoutePickerView(frame: frame)
    super.init()
    picker.backgroundColor = .clear
    picker.prioritizesVideoDevices = false
    if let args = arguments as? [String: Any], let argb = args["color"] as? Int {
      let color = UIColor(
        red: CGFloat((argb >> 16) & 0xFF) / 255,
        green: CGFloat((argb >> 8) & 0xFF) / 255,
        blue: CGFloat(argb & 0xFF) / 255,
        alpha: CGFloat((argb >> 24) & 0xFF) / 255
      )
      picker.tintColor = color
      picker.activeTintColor = color
    }
  }

  func view() -> UIView { picker }
}

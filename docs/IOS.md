# iOS

Kod hazır; bu geliştirme ortamında macOS / Xcode olmadığı için derleme
yalnızca GitHub Actions'ta (CI → "iOS build", imzasız) denenir.

## Var olanlar

- Arka planda çalma (`UIBackgroundModes: audio`), Kontrol Merkezi ve kilit
  ekranı (audio_service), kulaklık tuşları
- **AirPlay:** tam ekran oynatıcıdaki çıkış düğmesi → "AirPlay" (sistemin
  kendi cihaz seçicisi, `ios/Runner/AirPlayButton.swift`)
- **CarPlay:** Android Auto ile aynı kütüphane ağacı
  (`ios/Runner/CarPlaySceneDelegate.swift`, Dart tarafı
  `lib/player/carplay_bridge.dart`). Uygulama telefonda en az bir kez
  açılmış olmalıdır.
- DLNA ve yerel ağda Jellyfin keşfi (yerel ağ izni metni `Info.plist`'te)
- HTTP sunucular için App Transport Security istisnası
- Gizlilik bildirimi (`ios/Runner/PrivacyInfo.xcprivacy`): izleme yok, veri
  toplanmaz; UserDefaults ve dosya tarihleri kullanımı gerekçeleriyle
- Dokunsal geri bildirim (çal / duraklat / atla), iOS'ta geri kaydırma
- Ekolayzer, Android Auto ayarları ve ana ekran widget'ı iOS'ta gizli

## Apple'dan izin gerekenler

İkisi de Apple geliştirici hesabından ayrıca istenir; onaylanınca
`ios/Runner/Runner.entitlements.carplay` dosyası `Runner.entitlements`
olarak adlandırılır ve Xcode'da Runner hedefinin `CODE_SIGN_ENTITLEMENTS`
ayarına verilir.

- `com.apple.developer.carplay-audio`: CarPlay'de görünmek için
- `com.apple.developer.networking.multicast`: yerel ağda Jellyfin'i UDP ile
  bulmak için (izin yokken adres elle girilir)

## App Store

Dağıtım kararı şu an yalnızca F-Droid + GitHub. App Store için ayrıca:
Apple geliştirici hesabı, imzalama, ekran görüntüleri ve App Store metinleri
gerekir. Bu adımlar henüz yapılmadı.

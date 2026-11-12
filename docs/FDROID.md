# F-Droid'e başvuru rehberi

Melody yalnızca F-Droid'de (ve GitHub sürümlerinde APK olarak) yayınlanır.
F-Droid uygulamayı **kendi sunucularında kaynak koddan derler** ve kendi
anahtarıyla imzalar. Bu yüzden depodaki her şey açık kaynak olmalı ve
hazır derlenmiş ikili dosya indirilmemeli.

## 1. Hazırlık durumu

| Şart | Durum |
|---|---|
| Özgür lisans (MIT) | ✅ |
| Kapalı kaynak bağımlılık yok (Play Services, Firebase, Cast SDK) | ✅ derlenen APK'da kontrol edildi |
| Google'ın şifreli bağımlılık raporu kapalı (`dependenciesInfo`) | ✅ |
| Özgün uygulama ikonu | ✅ |
| Mağaza metinleri (`fastlane/metadata/android`, en / tr / az) | ✅ |
| İmzasız derleme seçeneği (`MELODY_UNSIGNED=1`) | ✅ |
| `pubspec.lock` depoda | ✅ |
| SQLite kaynaktan derleniyor | ✅ resmî 3.54.1 kaynağı, bkz. 2. madde |
| Depo herkese açık | ❌ |
| Sürüm etiketi (`v0.x.y`) ve GitHub sürümü | ✅ etiket gelince otomatik |
| Ekran görüntüleri | ✅ `en-US/images/phoneScreenshots` (diğer diller buna düşer) |

## 2. SQLite

`package:sqlite3` varsayılan olarak hazır derlenmiş SQLite kütüphanesini
GitHub'dan indirir; F-Droid bunu kabul etmez. Bu yüzden resmî SQLite kaynağı
(`third_party/sqlite/sqlite3.c`, public domain) depoda tutulur ve
`pubspec.yaml`'daki `hooks.user_defines.sqlite3` ayarıyla derleme sırasında
kaynaktan derlenir. Güncellemek için `third_party/sqlite/README.md`'ye bak.

## 3. Sürüm yayınlama (her sürümde)

1. `pubspec.yaml` içindeki `version:` değerini artır (ör. `0.3.0+3`; `+`'dan
   sonraki sayı her sürümde büyümeli).
2. `fastlane/metadata/android/<dil>/changelogs/<sayı>.txt` dosyalarını yaz.
3. Ana dala birleştir ve etiketle:

   ```bash
   git tag v0.3.0
   git push origin v0.3.0
   ```

Etiket gelince GitHub Actions (`.github/workflows/release.yml`) APK'ları
derler ve GitHub sürümüne ekler: `melody-<sürüm>.apk` (tüm işlemciler) ile
`arm64-v8a`, `armeabi-v7a` ve `x86_64` için ayrı dosyalar. Sürüm notu
`fastlane/metadata/android/tr-TR/changelogs/<sayı>.txt` dosyasından alınır.
Etiket, `pubspec.yaml`'daki sürümle aynı olmalıdır.

Bu APK'lar depoda **olmayan** kendi anahtarımızla imzalanır. Anahtar GitHub
deposunun gizli değişkenlerinde (Settings → Secrets and variables →
Actions) durur:

- `MELODY_KEYSTORE`: anahtar dosyasının base64 hâli (takma ad `melody`)
- `MELODY_KEYSTORE_PASSWORD`: dosyanın ve anahtarın şifresi

Anahtar dosyasının bir yedeği güvenli bir yerde saklanmalıdır; kaybolursa
yeni APK'lar eskilerinin üzerine kurulamaz.

F-Droid uygulamayı bir kez kabul ettikten sonra yeni etiketleri kendisi
bulur ve yeni sürümü birkaç gün içinde yayınlar (`AutoUpdateMode`).
F-Droid'de yayınlanan APK (F-Droid'in kendi kalıcı anahtarıyla imzalı)
f-droid.org'dan indirilip aynı GitHub sürümüne, debug APK'nın yanına
eklenir:

```bash
gh release upload v0.5.0 io.github.engineer948.melody_6.apk
```

## 4. İlk başvuru

İki yol var.

**Kolay yol: istek aç.** https://gitlab.com/fdroid/rfp/-/issues adresinde
GitLab hesabıyla yeni bir "Request For Packaging" aç. Depo adresini, lisansı
ve kısa açıklamayı yaz. Bir gönüllü tarifi hazırlar; bu haftalar, bazen
aylar sürebilir.

**Hızlı yol: tarifi kendin gönder.**

1. GitLab hesabı aç, https://gitlab.com/fdroid/fdroiddata deposunu fork'la.
2. `docs/fdroid/io.github.engineer948.melody.yml` dosyasını fork'undaki
   `metadata/io.github.engineer948.melody.yml` konumuna kopyala.
3. İstersen yerelde dene (Linux / Docker):

   ```bash
   fdroid readmeta
   fdroid lint io.github.engineer948.melody
   fdroid build -v -l io.github.engineer948.melody
   ```

4. Commit'le, fork'una push'la ve fdroiddata'ya merge request aç. GitLab CI
   uygulamayı derler; hata verirse günlüğü oku, düzelt, tekrar push'la.
5. İnceleyenlerin sorularını yanıtla. Birleştirildikten sonra uygulama
   genellikle birkaç gün içinde F-Droid'de görünür.

## 5. Dikkat

- **Uygulama kimliği** `io.github.engineer948.melody`; ilk yayından sonra
  değiştirilemez (değiştirmek yeni bir uygulama demektir).
- **Tarif taslaktır.** Flutter sürümü (`srclibs: flutter@3.47.9`) ve çıktı
  yolu F-Droid'in derleme sunucusunda doğrulanmadı.
- F-Droid kendi anahtarıyla imzaladığı için, GitHub'daki APK ile
  F-Droid'in imzaladığı APK birbirinin üzerine güncellenemez; birinden
  diğerine geçmek için uygulamayı kaldırıp yeniden kurmak gerekir.

## 6. Ekran görüntüleri

`fastlane/metadata/android/en-US/images/phoneScreenshots/` altındaki
görüntülerde yalnızca CC0 (kamu malı) albüm kapakları vardır; kaynakları
aynı klasördeki `CREDITS.md`'de. Gerçek kullanıcı ekranlarından alındı,
telifli kapaklar ve adlar bunlarla değiştirildi.

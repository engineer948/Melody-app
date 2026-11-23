/// Typefaces bundled with the app (all SIL Open Font License 1.1).
///
/// Every font covers Turkish and Azerbaijani letters, including `ə`.
enum AppFont {
  /// The platform's own font (SF on iOS, Roboto or the vendor font on
  /// Android).
  system(null, ''),

  /// Work Sans, the default.
  workSans('WorkSans', 'Work Sans'),

  /// Inter.
  inter('Inter', 'Inter'),

  /// Roboto.
  roboto('Roboto', 'Roboto'),

  /// Nunito.
  nunito('Nunito', 'Nunito'),

  /// Lora, a serif.
  lora('Lora', 'Lora'),

  /// JetBrains Mono, a monospace.
  jetBrainsMono('JetBrainsMono', 'JetBrains Mono');

  AppFont(this.family, this.displayName);

  /// Family declared in `pubspec.yaml`; `null` for the platform font.
  final String? family;

  /// Name shown in the picker (font names are not translated).
  final String displayName;
}

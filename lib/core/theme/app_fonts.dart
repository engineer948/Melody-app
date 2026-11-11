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

  /// IBM Plex Sans.
  ibmPlexSans('IBMPlexSans', 'IBM Plex Sans'),

  /// Source Sans 3.
  sourceSans3('SourceSans3', 'Source Sans 3'),

  /// DM Sans.
  dmSans('DMSans', 'DM Sans'),

  /// Plus Jakarta Sans.
  plusJakartaSans('PlusJakartaSans', 'Plus Jakarta Sans'),

  /// Geist.
  geist('Geist', 'Geist'),

  /// Onest.
  onest('Onest', 'Onest'),

  /// Albert Sans.
  albertSans('AlbertSans', 'Albert Sans'),

  /// Public Sans.
  publicSans('PublicSans', 'Public Sans'),

  /// Montserrat.
  montserrat('Montserrat', 'Montserrat'),

  /// Mulish.
  mulish('Mulish', 'Mulish'),

  /// Nunito.
  nunito('Nunito', 'Nunito'),

  /// Lexend, designed for readability.
  lexend('Lexend', 'Lexend'),

  /// Raleway.
  raleway('Raleway', 'Raleway'),

  /// Quicksand.
  quicksand('Quicksand', 'Quicksand'),

  /// Comfortaa.
  comfortaa('Comfortaa', 'Comfortaa'),

  /// Exo 2.
  exo2('Exo2', 'Exo 2'),

  /// Space Grotesk.
  spaceGrotesk('SpaceGrotesk', 'Space Grotesk'),

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

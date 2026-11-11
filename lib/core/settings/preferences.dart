import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'preferences.g.dart';

/// Synchronous key-value store, loaded once before the first frame.
///
/// Must be overridden in the root `ProviderScope`.
@Riverpod(keepAlive: true)
SharedPreferences preferences(Ref ref) =>
    throw UnimplementedError('preferencesProvider must be overridden');

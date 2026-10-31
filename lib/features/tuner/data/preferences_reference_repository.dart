import 'package:shared_preferences/shared_preferences.dart';

import '../domain/reference_repository.dart';
import '../domain/tuning_reference.dart';

class PreferencesReferenceRepository implements ReferenceRepository {
  PreferencesReferenceRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _referenceKey = 'tuner.reference_hz';
  final SharedPreferencesAsync _preferences;

  @override
  Future<double> load() async => TuningReference.normalize(
    await _preferences.getDouble(_referenceKey) ?? TuningReference.defaultHz,
  );

  @override
  Future<void> save(double referenceHz) => _preferences.setDouble(
    _referenceKey,
    TuningReference.normalize(referenceHz),
  );
}

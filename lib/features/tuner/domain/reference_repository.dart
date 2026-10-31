abstract interface class ReferenceRepository {
  Future<double> load();
  Future<void> save(double referenceHz);
}

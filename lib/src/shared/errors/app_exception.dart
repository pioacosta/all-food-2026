// Base comun para excepciones de dominio con mensaje apto para UI.
abstract class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

import 'dni_qr_data.dart';

DniQrData parsearQrDni(String raw) {
  final limpio = raw.replaceAll('\u0000', '').replaceAll('"', '').trim();

  final separadorPrincipal =
      limpio.contains('@') ? '@' : (limpio.contains('|') ? '|' : '\n');

  final tokens =
      limpio
          .split(separadorPrincipal)
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

  String? apellido;
  String? nombre;
  String? dni;

  for (final token in tokens) {
    if (dni == null && RegExp(r'^\d{7,8}$').hasMatch(token)) {
      dni = token;
      continue;
    }
  }

  final letras =
      tokens
          .where((t) => RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñÜü ]{2,}$').hasMatch(t))
          .toList();

  if (letras.isNotEmpty) apellido = letras.first;
  if (letras.length > 1) nombre = letras[1];

  return DniQrData(nombre: nombre, apellido: apellido, dni: dni);
}
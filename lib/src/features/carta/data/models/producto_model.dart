class ProductoModel {
  const ProductoModel({
    required this.id,
    required this.tipo,
    required this.nombre,
    required this.descripcion,
    required this.tiempoMin,
    required this.precio,
    required this.foto1,
    required this.foto2,
    required this.foto3,
  });

  factory ProductoModel.fromMap(Map<String, dynamic> map) {
    return ProductoModel(
      id: map['id'] as String,
      tipo: map['tipo'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String,
      tiempoMin: map['tiempo_elaboracion_min'] as int,
      precio: (map['precio'] as num).toDouble(),
      foto1: map['foto_1_url'] as String,
      foto2: map['foto_2_url'] as String,
      foto3: map['foto_3_url'] as String,
    );
  }

  final String id;
  final String tipo;
  final String nombre;
  final String descripcion;
  final int tiempoMin;
  final double precio;
  final String foto1;
  final String foto2;
  final String foto3;

  List<String> get fotos => [foto1, foto2, foto3];
}
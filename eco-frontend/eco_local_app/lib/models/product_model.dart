// Clases Dart (Copia de los modelos del backend)

class Dpp {
  final String carbonFootprint;
  final String origin;
  final String materials;
  final String recyclability;

  Dpp({
    required this.carbonFootprint,
    required this.origin,
    required this.materials,
    required this.recyclability,
  });

  factory Dpp.fromJson(Map<String, dynamic> json) {
    return Dpp(
      carbonFootprint: json['carbon_footprint'] ?? 'N/A',
      origin: json['origin'] ?? 'Unknown',
      materials: json['materials'] ?? 'Unknown',
      recyclability: json['recyclability'] ?? 'Unknown',
    );
  }
}

class ProductModel {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final Dpp dpp;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.dpp,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Product',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['image_url'] ?? 'https://via.placeholder.com/300',
      dpp: Dpp.fromJson(json['dpp'] ?? {}),
    );
  }
}

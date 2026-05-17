class Shop {
  final String name;
  final String activity;
  final String category;
  final String address;
  final String neighborhood;
  final bool isCommercialAxis;
  final double latitude;
  final double longitude;

  Shop({
    required this.name,
    required this.activity,
    required this.category,
    required this.address,
    required this.neighborhood,
    required this.isCommercialAxis,
    required this.latitude,
    required this.longitude,
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    // Extraemos las coordenadas del objeto GeoJSON Point: {"type": "Point", "coordinates": [lng, lat]}
    final location = json['location'] as Map<String, dynamic>;
    final coordinates = location['coordinates'] as List<dynamic>;
    
    return Shop(
      name: json['name'] ?? 'Sin nombre',
      activity: json['activity'] ?? 'Actividad no definida',
      category: json['category'] ?? 'Sin categoría',
      address: json['address'] ?? 'Sin dirección',
      neighborhood: json['neighborhood'] ?? 'Barrio desconocido',
      isCommercialAxis: json['is_commercial_axis'] ?? false,
      longitude: (coordinates[0] as num).toDouble(),
      latitude: (coordinates[1] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'activity': activity,
      'category': category,
      'address': address,
      'neighborhood': neighborhood,
      'is_commercial_axis': isCommercialAxis,
      'location': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
    };
  }
}

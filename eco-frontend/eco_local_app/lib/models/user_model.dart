// Clases Dart (Copia de los modelos del backend)

class UserModel {
  final String? id;
  final String? owner;
  final String name;
  final String? surnames;
  final String email;
  final String? password; // Solo para registro
  final String? token;

  UserModel({
    this.id,
    this.owner,
    required this.name,
    this.surnames,
    required this.email,
    this.password,
    this.token,
  });

  // Constructor from JSON (respuesta del backend)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Si el JSON viene con la estructura {"user": {...}, "token": "..."}
    if (json.containsKey('user') && json.containsKey('token')) {
      final userJson = json['user'] as Map<String, dynamic>;
      return UserModel(
        id: (userJson['_id'] ?? userJson['id']) as String?,
        owner: userJson['owner'] as String?,
        name: userJson['name'] as String,
        surnames: userJson['surnames'] as String?,
        email: userJson['email'] as String,
        token: json['token'] as String?,
      );
    }
    
    return UserModel(
      id: (json['_id'] ?? json['id']) as String?,
      owner: json['owner'] as String?,
      name: json['name'] as String? ?? '',
      surnames: json['surnames'] as String?,
      email: json['email'] as String? ?? '',
      token: json['token'] as String?,
    );
  }

  // Convertir a JSON (para envío al backend)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (owner != null) 'owner': owner,
      'name': name,
      if (surnames != null && surnames!.isNotEmpty) 'surnames': surnames,
      'email': email,
      if (password != null) 'password': password,
      if (token != null) 'token': token,
    };
  }

  // Crear copia con cambios
  UserModel copyWith({
    String? id,
    String? owner,
    String? name,
    String? surnames,
    String? email,
    String? password,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      owner: owner ?? this.owner,
      name: name ?? this.name,
      surnames: surnames ?? this.surnames,
      email: email ?? this.email,
      password: password ?? this.password,
      token: token ?? this.token,
    );
  }
}

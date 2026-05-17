class UserModel {
  final String name;
  final String surnames;
  final String email;
  final String password;
  final String? phone;

  UserModel({
    required this.name,
    required this.surnames,
    required this.email,
    required this.password,
    this.phone,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] ?? '',
      surnames: json['surnames'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'surnames': surnames,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
    };
  }
}
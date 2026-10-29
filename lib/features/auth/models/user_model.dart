class UserModel {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? address;

  UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] ?? '',
      fullName: json['full_name'],
      phone: json['phone'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'address': address,
    };
  }
}
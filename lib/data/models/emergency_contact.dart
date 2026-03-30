import 'dart:convert';

class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.phone,
  });

  final String name;
  final String phone;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: (map['name'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
    );
  }

  factory EmergencyContact.fromJson(String source) {
    return EmergencyContact.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}

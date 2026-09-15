/// A (simulated) emergency contact. Never actually contacted.
class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.phone,
    this.method = 'simulated',
  });

  final String name;
  final String phone;
  final String method;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name'] as String,
      phone: json['phone'] as String,
      method: json['method'] as String? ?? 'simulated',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'method': method,
      };
}

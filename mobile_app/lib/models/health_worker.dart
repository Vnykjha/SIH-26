import 'package:uuid/uuid.dart';

class HealthWorker {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String role;
  final DateTime createdAt;

  HealthWorker({
    String? id,
    required this.name,
    required this.email,
    required this.passwordHash,
    this.role = 'health_worker',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'worker_id': id,
      'name': name,
      'email': email,
      'password_hash': passwordHash,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory HealthWorker.fromMap(Map<String, dynamic> map) {
    return HealthWorker(
      id: map['worker_id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      role: (map['role'] as String?) ?? 'health_worker',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

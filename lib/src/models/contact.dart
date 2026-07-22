class Contact {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? company;
  final String source;
  final String status;
  final double value;
  final List<String> tags;
  final String? assignedTo;
  final String optInStatus;
  final String? createdAt;
  final String? updatedAt;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.company,
    this.source = 'manual',
    this.status = 'new',
    this.value = 0.0,
    this.tags = const [],
    this.assignedTo,
    this.optInStatus = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] != null) {
      if (json['tags'] is List) {
        parsedTags = (json['tags'] as List).map((e) => e.toString()).toList();
      }
    }

    final rawPhone = (json['whatsapp_contact_id'] ?? json['phone'] ?? json['contact_id'] ?? '').toString();
    final rawValue = json['value'] ?? json['score'] ?? 0;
    double parsedValue = 0.0;
    if (rawValue is num) {
      parsedValue = rawValue.toDouble();
    } else if (rawValue != null) {
      parsedValue = double.tryParse(rawValue.toString()) ?? 0.0;
    }

    return Contact(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unnamed Contact').toString(),
      phone: rawPhone,
      email: json['email']?.toString(),
      company: json['company']?.toString(),
      source: (json['source'] ?? 'manual').toString(),
      status: (json['status'] ?? 'new').toString(),
      value: parsedValue,
      tags: parsedTags,
      assignedTo: json['assigned_to']?.toString() ?? json['assignedTo']?.toString(),
      optInStatus: (json['opt_in_status'] ?? json['optInStatus'] ?? 'active').toString(),
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString(),
      updatedAt: json['updated_at']?.toString() ?? json['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'whatsapp_contact_id': phone,
      'email': email,
      'company': company,
      'source': source,
      'status': status,
      'value': value,
      'tags': tags,
      'assigned_to': assignedTo,
      'opt_in_status': optInStatus,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Contact copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? company,
    String? source,
    String? status,
    double? value,
    List<String>? tags,
    String? assignedTo,
    String? optInStatus,
    String? createdAt,
    String? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      company: company ?? this.company,
      source: source ?? this.source,
      status: status ?? this.status,
      value: value ?? this.value,
      tags: tags ?? this.tags,
      assignedTo: assignedTo ?? this.assignedTo,
      optInStatus: optInStatus ?? this.optInStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

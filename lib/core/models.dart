import 'package:intl/intl.dart';

typedef Json = Map<String, dynamic>;

String iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
String fmtDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);
String fmtDateShort(DateTime d) => DateFormat('dd MMM').format(d);
String fmtQty(num? v) {
  if (v == null) return '0';
  return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
String money(num? v) {
  if (v == null) return '₹0';
  return '₹${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2)}';
}

class Profile {
  final String id, name, role, language;
  final String? phone, alternatePhone, photoUrl;
  final bool isBlocked;

  Profile({
    required this.id,
    required this.name,
    required this.role,
    required this.language,
    this.phone,
    this.alternatePhone,
    this.photoUrl,
    this.isBlocked = false,
  });

  factory Profile.fromJson(Json j) => Profile(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        role: j['role'] ?? 'customer',
        language: j['language'] ?? 'en',
        phone: j['phone'],
        alternatePhone: j['alternate_phone'],
        photoUrl: j['photo_url'],
        isBlocked: j['is_blocked'] ?? false,
      );
}

class Address {
  final String id, userId, label, line, pincode;
  final String? landmark, contactPhone;
  final bool isDefault;
  final double? latitude, longitude;

  Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.line,
    required this.pincode,
    this.landmark,
    this.contactPhone,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Json j) => Address(
        id: j['id'] ?? '',
        userId: j['user_id'] ?? '',
        label: j['label'] ?? 'Home',
        line: j['line'] ?? '',
        pincode: j['pincode'] ?? '',
        landmark: j['landmark'],
        contactPhone: j['contact_phone'],
        isDefault: j['is_default'] ?? false,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
      );
}

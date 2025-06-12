// Models

enum CouponType {
  common,
  specificShop, // own shops
  multiShop, // multiple shops
}

class Coupon {
  final String code;
  final String description;
  final double discount;
  final DateTime expiryDate;
  final CouponType type;
  final List<Map<String, String>> applicableShops;
  final DateTime createdAt;
  final int maxUsagePerUser;

  Coupon({
    required this.code,
    required this.description,
    required this.discount,
    required this.expiryDate,
    required this.type,
    required this.applicableShops,
    required this.createdAt,
    required this.maxUsagePerUser,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'description': description,
        'discount': discount,
        'expiryDate': expiryDate.toIso8601String(),
        'type': type.name,
        'applicableShops': applicableShops,
        'createdAt': createdAt.toIso8601String(),
        'maxUsagePerUser': maxUsagePerUser,
      };

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
        code: json['code'],
        description: json['description'],
        discount: (json['discount'] as num).toDouble(),
        expiryDate: DateTime.parse(json['expiryDate']),
        type: CouponType.values.firstWhere((e) => e.name == json['type']),
        applicableShops: List<Map<String, String>>.from(
          (json['applicableShops'] as List)
              .map((e) => Map<String, String>.from(e)),
        ),
        createdAt: DateTime.parse(json['createdAt']),
        maxUsagePerUser: json['maxUsagePerUser'] ?? 1,
      );
}

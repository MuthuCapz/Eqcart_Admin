import 'package:flutter/cupertino.dart';

enum CouponType {
  common,
  specificShop,
  multiShop,
}

class Coupon {
  final String code;
  final String description;
  final double discount;
  final double minimumOrderValue;
  final DateTime validFrom;
  final DateTime validTo;
  final CouponType type;
  final List<Map<String, String>> applicableShops;
  final DateTime createdAt;
  final int maxUsagePerUser;

  Coupon({
    required this.code,
    required this.description,
    required this.discount,
    required this.minimumOrderValue,
    required this.validFrom,
    required this.validTo,
    required this.type,
    required this.applicableShops,
    required this.createdAt,
    required this.maxUsagePerUser,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'description': description,
        'discount': discount,
        'minimumOrderValue': minimumOrderValue,
        'validFrom': validFrom.toIso8601String(),
        'validTo': validTo.toIso8601String(),
        'type': type.name,
        'applicableShops': applicableShops,
        'createdAt': createdAt.toIso8601String(),
        'maxUsagePerUser': maxUsagePerUser,
      };

  factory Coupon.fromJson(Map<String, dynamic> json) {
    try {
      // Handle null values with defaults
      final code = json['code'] as String? ?? '';
      final description = json['description'] as String? ?? '';
      final discount = (json['discount'] as num?)?.toDouble() ?? 0.0;
      final minOrderValue =
          (json['minimumOrderValue'] as num?)?.toDouble() ?? 0.0;
      final maxUsage = json['maxUsagePerUser'] as int? ?? 1;

      // Parse dates with fallbacks
      final now = DateTime.now();

      final validFrom = json['validFrom'] != null
          ? DateTime.parse(json['validFrom'] as String)
          : now;
      final validTo = json['validTo'] != null
          ? DateTime.parse(json['validTo'] as String)
          : now.add(const Duration(days: 7));
      final createdAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : now;

      // Handle coupon type
      final type = json['type'] != null
          ? CouponType.values.firstWhere(
              (e) => e.name == json['type'] as String,
              orElse: () => CouponType.common,
            )
          : CouponType.common;

      // Handle applicable shops
      List<Map<String, String>> shops = [];
      if (json['applicableShops'] != null) {
        shops = List<Map<String, String>>.from(
          (json['applicableShops'] as List).map(
            (e) => Map<String, String>.from(e as Map),
          ),
        );
      }

      return Coupon(
        code: code,
        description: description,
        discount: discount,
        minimumOrderValue: minOrderValue,
        validFrom: validFrom,
        validTo: validTo,
        type: type,
        applicableShops: shops,
        createdAt: createdAt,
        maxUsagePerUser: maxUsage,
      );
    } catch (e) {
      debugPrint('Error parsing coupon: $e');
      // Return a default coupon if parsing fails
      final now = DateTime.now();
      return Coupon(
        code: 'INVALID',
        description: 'Invalid coupon data',
        discount: 0,
        minimumOrderValue: 0,
        validFrom: now,
        validTo: now,
        type: CouponType.common,
        applicableShops: [],
        createdAt: now,
        maxUsagePerUser: 1,
      );
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CreatedCoupon {
  final String code;
  final String description;
  final double discount;
  final double fixedAmount;
  final int maxUsagePerUser;
  final double minimumOrderValue;
  final DateTime validFrom;
  final DateTime validTo;
  final String shopName;

  CreatedCoupon({
    required this.code,
    required this.description,
    required this.discount,
    required this.fixedAmount,
    required this.maxUsagePerUser,
    required this.minimumOrderValue,
    required this.validFrom,
    required this.validTo,
    required this.shopName,
  });

  factory CreatedCoupon.fromJson(Map<String, dynamic> json) {
    try {
      return CreatedCoupon(
        code: json['couponCode'] ?? 'INVALID',
        description: json['description'] ?? '',
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        fixedAmount: (json['fixedAmount'] as num?)?.toDouble() ?? 0.0,
        maxUsagePerUser: (json['maxUsagePerUser'] as num?)?.toInt() ?? 1,
        minimumOrderValue:
            (json['minimumOrderValue'] as num?)?.toDouble() ?? 0.0,
        validFrom:
            (json['validFrom'] as Timestamp?)?.toDate() ?? DateTime.now(),
        validTo: (json['validTo'] as Timestamp?)?.toDate() ?? DateTime.now(),
        shopName: json['shopName'] ?? '',
      );
    } catch (e) {
      debugPrint('Error parsing CreatedCoupon: $e');
      return CreatedCoupon(
        code: 'INVALID',
        description: '',
        discount: 0.0,
        fixedAmount: 0.0,
        maxUsagePerUser: 0,
        minimumOrderValue: 0.0,
        validFrom: DateTime.now(),
        validTo: DateTime.now(),
        shopName: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'couponCode': code,
      'description': description,
      'discount': discount,
      'fixedAmount': fixedAmount,
      'maxUsagePerUser': maxUsagePerUser,
      'minimumOrderValue': minimumOrderValue,
      'validFrom': Timestamp.fromDate(validFrom),
      'validTo': Timestamp.fromDate(validTo),
      'shopName': shopName,
    };
  }

  bool get isFixedAmountCoupon => fixedAmount > 0;
  bool get isPercentageCoupon => discount > 0;

  String get discountDescription {
    if (isFixedAmountCoupon) {
      return '₹${fixedAmount.toStringAsFixed(2)} off';
    } else if (isPercentageCoupon) {
      return '${discount.toStringAsFixed(0)}% off';
    }
    return 'No discount';
  }
}

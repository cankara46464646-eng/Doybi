import 'package:flutter/material.dart';

/// Bir mahalleye teslimat koşulları.
class Zone {
  final int min; // minimum sepet (₺)
  final int fee; // teslimat ücreti (₺), 0 = ücretsiz
  final String eta; // "20-30"
  const Zone(this.min, this.fee, this.eta);
}

class MenuItem {
  final String id;
  final String name;
  final String desc;
  final int price;
  final String category;
  const MenuItem(this.id, this.name, this.price, this.category, {this.desc = ''});
}

class Restaurant {
  final String id;
  final String name;
  final String initials;
  final Color color;
  final Color ink;
  final String cuisine;
  final double rating;
  final Map<String, Zone> zones;
  final bool cash;
  final bool card;
  final String address;
  final List<MenuItem> menu;
  const Restaurant({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    required this.ink,
    required this.cuisine,
    required this.rating,
    required this.zones,
    required this.cash,
    required this.card,
    required this.address,
    required this.menu,
  });

  List<String> get categories {
    final out = <String>[];
    for (final m in menu) {
      if (!out.contains(m.category)) out.add(m.category);
    }
    return out;
  }
}

class CartLine {
  final MenuItem item;
  int qty;
  CartLine(this.item, this.qty);
  int get total => item.price * qty;
}

enum OrderStatus { bekliyor, hazirlaniyor, yolda, teslim, iptal, edilemedi }

extension OrderStatusText on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.bekliyor:
        return 'Restoran onayı bekleniyor';
      case OrderStatus.hazirlaniyor:
        return 'Hazırlanıyor';
      case OrderStatus.yolda:
        return 'Yolda';
      case OrderStatus.teslim:
        return 'Teslim edildi';
      case OrderStatus.iptal:
        return 'İptal edildi';
      case OrderStatus.edilemedi:
        return 'Teslim edilemedi';
    }
  }

  bool get closed => this == OrderStatus.teslim || this == OrderStatus.iptal || this == OrderStatus.edilemedi;
}

class Order {
  final String id;
  final Restaurant restaurant;
  final List<CartLine> lines;
  final int subtotal;
  final int deliveryFee;
  final String payment; // 'nakit' | 'kart'
  final String note;
  final String address;
  final String phone;
  final DateTime createdAt;
  OrderStatus status;
  int prepMin;
  String? reason;
  bool collected;

  Order({
    required this.id,
    required this.restaurant,
    required this.lines,
    required this.subtotal,
    required this.deliveryFee,
    required this.payment,
    required this.note,
    required this.address,
    required this.phone,
    required this.createdAt,
    this.status = OrderStatus.bekliyor,
    this.prepMin = 20,
    this.collected = false,
  });

  int get total => subtotal + deliveryFee;
  String get paymentLabel => payment == 'kart' ? 'Kapıda kart' : 'Kapıda nakit';
  String get itemsText => lines.map((l) => '${l.qty}× ${l.item.name}').join(', ');
}

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/demo.dart';
import '../data/models.dart';

/// Uygulamanın tüm durumu. İlk sürümde telefonda tutulur; sunucu bağlanınca
/// siparişler oradan gelecek.
class AppState extends ChangeNotifier {
  String? mahalle;
  String addressLine = '';
  String? phone; // SMS ile doğrulanmış numara

  Restaurant? cartRestaurant;
  final List<CartLine> cart = [];
  final List<Order> orders = [];

  /// Deneme: restoran siparişi kendisi ilerletsin (tek telefonla denerken).
  bool autoRestaurant = true;
  final Map<String, Timer> _timers = {};
  int _seq = 1042;

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      mahalle = p.getString('mahalle');
      addressLine = p.getString('address') ?? '';
      phone = p.getString('phone');
      autoRestaurant = p.getBool('auto') ?? true;
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (mahalle != null) p.setString('mahalle', mahalle!);
      p.setString('address', addressLine);
      if (phone != null) {
        p.setString('phone', phone!);
      } else {
        p.remove('phone');
      }
      p.setBool('auto', autoRestaurant);
    } catch (_) {}
  }

  // ---------- adres ve hesap ----------
  void setAddress(String m, String line) {
    mahalle = m;
    addressLine = line.trim();
    if (cartRestaurant != null && zoneFor(cartRestaurant!) == null) clearCart();
    _save();
    notifyListeners();
  }

  void verifyPhone(String p) {
    phone = p;
    _save();
    notifyListeners();
  }

  void signOut() {
    phone = null;
    _save();
    notifyListeners();
  }

  void setAuto(bool v) {
    autoRestaurant = v;
    _save();
    notifyListeners();
  }

  String get fullAddress => [if (mahalle != null) '$mahalle Mah.', if (addressLine.isNotEmpty) addressLine].join(' ');

  // ---------- restoranlar ----------
  Zone? zoneFor(Restaurant r) => mahalle == null ? null : r.zones[mahalle];
  List<Restaurant> get nearby => restaurants.where((r) => zoneFor(r) != null).toList();

  // ---------- sepet ----------
  int qtyOf(MenuItem i) {
    for (final l in cart) {
      if (l.item.id == i.id) return l.qty;
    }
    return 0;
  }

  int get cartCount => cart.fold(0, (a, l) => a + l.qty);
  int get subtotal => cart.fold(0, (a, l) => a + l.total);
  Zone? get cartZone => cartRestaurant == null ? null : zoneFor(cartRestaurant!);
  int get deliveryFee => cartZone?.fee ?? 0;
  int get minCart => cartZone?.min ?? 0;
  bool get minOk => subtotal >= minCart;
  int get total => subtotal + deliveryFee;

  /// Başka restoranın sepeti doluysa false döner.
  bool add(Restaurant r, MenuItem i) {
    if (cartRestaurant != null && cartRestaurant!.id != r.id && cart.isNotEmpty) return false;
    cartRestaurant = r;
    for (final l in cart) {
      if (l.item.id == i.id) {
        l.qty++;
        notifyListeners();
        return true;
      }
    }
    cart.add(CartLine(i, 1));
    notifyListeners();
    return true;
  }

  void remove(MenuItem i) {
    for (final l in cart) {
      if (l.item.id == i.id) {
        l.qty--;
        if (l.qty <= 0) cart.remove(l);
        break;
      }
    }
    if (cart.isEmpty) cartRestaurant = null;
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    cartRestaurant = null;
    notifyListeners();
  }

  // ---------- sipariş ----------
  Order placeOrder({required String payment, required String note}) {
    final r = cartRestaurant!;
    final o = Order(
      id: '#D-${_seq++}',
      restaurant: r,
      lines: cart.map((l) => CartLine(l.item, l.qty)).toList(),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      payment: payment,
      note: note.trim(),
      address: fullAddress,
      phone: phone ?? '',
      createdAt: DateTime.now(),
    );
    orders.insert(0, o);
    clearCart();
    if (autoRestaurant) _autoStep(o, 6);
    notifyListeners();
    return o;
  }

  List<Order> get activeOrders => orders.where((o) => !o.status.closed).toList();

  void _autoStep(Order o, int seconds) {
    _timers[o.id]?.cancel();
    _timers[o.id] = Timer(Duration(seconds: seconds), () {
      if (!autoRestaurant) return;
      switch (o.status) {
        case OrderStatus.bekliyor:
          accept(o, 20);
          break;
        case OrderStatus.hazirlaniyor:
          toRoad(o);
          break;
        case OrderStatus.yolda:
          deliver(o);
          break;
        default:
          break;
      }
    });
  }

  void customerCancel(Order o) {
    if (o.status != OrderStatus.bekliyor) return;
    o.status = OrderStatus.iptal;
    o.reason = 'Müşteri vazgeçti';
    _timers[o.id]?.cancel();
    notifyListeners();
  }

  // ---------- restoran tarafı ----------
  void setPrep(Order o, int m) {
    o.prepMin = m;
    notifyListeners();
  }

  void accept(Order o, int prep) {
    if (o.status != OrderStatus.bekliyor) return;
    o.status = OrderStatus.hazirlaniyor;
    o.prepMin = prep;
    if (autoRestaurant) _autoStep(o, 10);
    notifyListeners();
  }

  void reject(Order o, String reason) {
    if (o.status.closed) return;
    o.status = OrderStatus.iptal;
    o.reason = reason;
    _timers[o.id]?.cancel();
    notifyListeners();
  }

  void toRoad(Order o) {
    if (o.status != OrderStatus.hazirlaniyor) return;
    o.status = OrderStatus.yolda;
    if (autoRestaurant) _autoStep(o, 10);
    notifyListeners();
  }

  void deliver(Order o) {
    if (o.status != OrderStatus.yolda) return;
    o.status = OrderStatus.teslim;
    _timers[o.id]?.cancel();
    notifyListeners();
  }

  void fail(Order o, String reason) {
    if (o.status != OrderStatus.yolda) return;
    o.status = OrderStatus.edilemedi;
    o.reason = reason;
    _timers[o.id]?.cancel();
    notifyListeners();
  }

  void collect(Order o) {
    if (o.status != OrderStatus.teslim) return;
    o.collected = true;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final t in _timers.values) {
      t.cancel();
    }
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

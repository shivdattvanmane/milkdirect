import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models.dart';

/// All backend access (Supabase) lives here.
class Api {
  static SupabaseClient get client => Supabase.instance.client;
  static String get uid => client.auth.currentUser!.id;

  // ---------- Auth (Email + Password) ----------
  static Future<AuthResponse> signInWithPassword(String email, String password) =>
      client.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

  static Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) =>
      client.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password,
        data: data,
      );

  static Future<void> sendPasswordReset(String email) =>
      client.auth.resetPasswordForEmail(email.trim().toLowerCase());

  static Future<void> resendConfirmationEmail(String email) =>
      client.auth.resend(type: OtpType.signup, email: email.trim().toLowerCase());

  static Future<void> signOut() => client.auth.signOut();

  // ---------- Profile ----------
  static Future<Profile?> fetchProfile() async {
    final current = client.auth.currentUser;
    if (current == null) return null;
    final r = await client.from('mk_profiles').select().eq('id', current.id).maybeSingle();
    return r == null ? null : Profile.fromJson(r);
  }

  /// Customer profile registration
  static Future<void> createCustomerProfile({
    required String name,
    required String email,
    required String contactPhone,
    required String lang,
    required String pincode,
    required String addressLine,
    String? landmark,
    String? city,
    String? alternatePhone,
    String? photoUrl,
  }) async {
    final userEmail = email.trim().toLowerCase().isNotEmpty
        ? email.trim().toLowerCase()
        : (client.auth.currentUser?.email ?? '');

    await client.from('mk_profiles').upsert({
      'id': uid,
      'name': name.trim(),
      'phone': userEmail,
      'alternate_phone': contactPhone.trim().isNotEmpty ? contactPhone.trim() : alternatePhone,
      'photo_url': photoUrl,
      'role': 'customer',
      'language': lang,
    });

    await client.from('mk_addresses').insert({
      'user_id': uid,
      'label': 'Home',
      'line': addressLine.trim(),
      'landmark': (landmark ?? '').trim().isEmpty ? null : landmark!.trim(),
      'pincode': pincode.trim(),
      'contact_phone': contactPhone.trim(),
      'is_default': true,
    });
  }

  /// Supplier profile registration wizard
  static Future<void> createSupplierProfile({
    required String name,
    required String email,
    required String contactPhone,
    required String lang,
    required String type, // 'farmer' | 'milkman'
    required String shopName,
    required String village,
    required String pincode,
    List<String>? servicePincodes,
    String? upi,
    List<String>? deliverySlots,
    double? deliveryCharge,
    double? minOrderL,
    String? bankAccountNo,
    String? bankIfsc,
    String? fssaiNo,
    String? alternatePhone,
    String? photoUrl,
    List<dynamic>? documents,
  }) async {
    final userEmail = email.trim().toLowerCase().isNotEmpty
        ? email.trim().toLowerCase()
        : (client.auth.currentUser?.email ?? '');

    await client.from('mk_profiles').upsert({
      'id': uid,
      'name': name.trim(),
      'phone': userEmail,
      'alternate_phone': contactPhone.trim().isNotEmpty ? contactPhone.trim() : alternatePhone,
      'photo_url': photoUrl,
      'role': 'supplier',
      'language': lang,
    });

    final sp = await client
        .from('mk_supplier_profiles')
        .insert({
          'user_id': uid,
          'type': type,
          'shop_name': shopName.trim(),
          'village': village.trim(),
          'pincode': pincode.trim(),
          'upi_id': (upi ?? '').trim().isEmpty ? null : upi!.trim(),
          'delivery_slots': deliverySlots ?? ['morning_5_8', 'morning_8_10', 'evening_5_8'],
          'bank_account_no': bankAccountNo,
          'bank_ifsc': bankIfsc,
          'fssai_no': fssaiNo,
          'documents': documents ?? [],
          'verification_status': 'pending',
        })
        .select()
        .single();

    final pins = <String>{pincode.trim()};
    if (servicePincodes != null) {
      for (final p in servicePincodes) {
        if (p.trim().isNotEmpty) pins.add(p.trim());
      }
    }

    for (final pin in pins) {
      await client.from('mk_service_areas').upsert({'supplier_id': sp['id'], 'pincode': pin});
    }
  }

  /// Legacy helper for createProfile
  static Future<void> createProfile({
    required String name,
    required String role,
    required String lang,
    required String pincode,
    String? email,
    String? contactPhone,
    String? alternatePhone,
    String? photoUrl,
    String? supplierType,
    String? shopName,
    String? village,
    String? upi,
    String? addressLine,
    String? landmark,
  }) async {
    final em = email ?? client.auth.currentUser?.email ?? '';
    final ph = contactPhone ?? alternatePhone ?? '';
    if (role == 'supplier') {
      await createSupplierProfile(
        name: name,
        email: em,
        contactPhone: ph,
        lang: lang,
        type: supplierType ?? 'farmer',
        village: village ?? '',
        pincode: pincode,
        shopName: shopName ?? 'Dairy Farm',
        upi: upi,
        alternatePhone: alternatePhone,
        photoUrl: photoUrl,
      );
    } else {
      await createCustomerProfile(
        name: name,
        email: em,
        contactPhone: ph,
        lang: lang,
        pincode: pincode,
        addressLine: addressLine ?? village ?? '',
        landmark: landmark,
        alternatePhone: alternatePhone,
        photoUrl: photoUrl,
      );
    }
  }

  static Future<void> updateProfile({
    String? name,
    String? phone,
    String? alternatePhone,
    String? photoUrl,
  }) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (alternatePhone != null) updates['alternate_phone'] = alternatePhone;
    if (photoUrl != null) updates['photo_url'] = photoUrl;
    if (updates.isNotEmpty) {
      await client.from('mk_profiles').update(updates).eq('id', uid);
    }
  }

  // ---------- Address Book ----------
  static Future<List<Address>> myAddresses() async {
    final r = await client.from('mk_addresses').select().eq('user_id', uid).order('is_default', ascending: false);
    return List<Address>.from((r as List).map((a) => Address.fromJson(a as Json)));
  }

  static Future<Address?> myAddress() async {
    final r = await client.from('mk_addresses').select().eq('user_id', uid).order('is_default', ascending: false).limit(1).maybeSingle();
    return r == null ? null : Address.fromJson(r);
  }

  static Future<void> addAddress({
    required String label,
    required String line,
    required String pincode,
    String? landmark,
    String? contactPhone,
    bool isDefault = false,
  }) async {
    if (isDefault) {
      await client.from('mk_addresses').update({'is_default': false}).eq('user_id', uid);
    }
    await client.from('mk_addresses').insert({
      'user_id': uid,
      'label': label,
      'line': line,
      'landmark': landmark,
      'pincode': pincode,
      'contact_phone': contactPhone,
      'is_default': isDefault,
    });
  }

  static Future<void> setDefaultAddress(String addressId) async {
    await client.from('mk_addresses').update({'is_default': false}).eq('user_id', uid);
    await client.from('mk_addresses').update({'is_default': true}).eq('id', addressId);
  }

  static Future<void> deleteAddress(String addressId) =>
      client.from('mk_addresses').delete().eq('id', addressId);

  // ---------- Customer ----------
  static Future<List<Json>> suppliers({String? pincode, String? milkType, double? maxPrice}) async {
    var q = client
        .from('mk_supplier_profiles')
        .select('*, profiles:mk_profiles(name, phone, photo_url), products:mk_products(*), service_areas:mk_service_areas!inner(pincode)')
        .eq('verification_status', 'verified');

    if (pincode != null && pincode.isNotEmpty) {
      q = q.eq('service_areas.pincode', pincode);
    }
    final res = await q;
    var list = List<Json>.from(res);

    if (milkType != null && milkType != 'all') {
      list = list.where((s) {
        final prods = (s['products'] as List?) ?? [];
        return prods.any((p) => p['milk_type'] == milkType && p['available'] == true);
      }).toList();
    }
    return list;
  }

  static Future<Json?> todayDelivery() async {
    final today = iso(DateTime.now());
    final r = await client
        .from('mk_orders')
        .select('*, products:mk_products(milk_type, price_per_litre), supplier:mk_supplier_profiles(shop_name, village, profiles:mk_profiles(name, phone))')
        .eq('customer_id', uid)
        .eq('delivery_date', today)
        .maybeSingle();
    return r;
  }

  static Future<List<Json>> mySubscriptions() async => List<Json>.from(await client
      .from('mk_subscriptions')
      .select('*, products:mk_products(milk_type, price_per_litre), supplier_profiles:mk_supplier_profiles(shop_name, village, profiles:mk_profiles(name, phone))')
      .eq('customer_id', uid)
      .order('created_at', ascending: false));

  static Future<void> createSubscription({
    required String supplierId,
    required String productId,
    required double qty,
    required DateTime start,
    DateTime? end,
    String frequency = 'daily',
    List<int>? weekdays,
    String slot = 'morning_5_8',
    required String address,
    String? instructions,
    String paymentMode = 'cash',
    double deliveryCharge = 0,
  }) async {
    await client.from('mk_subscriptions').insert({
      'customer_id': uid,
      'supplier_id': supplierId,
      'product_id': productId,
      'quantity_l': qty,
      'frequency': frequency,
      'weekdays': weekdays ?? [1, 2, 3, 4, 5, 6, 7],
      'slot': slot,
      'start_date': iso(start),
      'end_date': end != null ? iso(end) : null,
      'address': address,
      'instructions': instructions,
      'payment_mode': paymentMode,
      'delivery_charge': deliveryCharge,
    });
  }

  static Future<void> setSubscriptionStatus(String id, String status) =>
      client.from('mk_subscriptions').update({'status': status}).eq('id', id);

  static Future<void> setSkipDates(String id, List<String> dates) =>
      client.from('mk_subscriptions').update({'skip_dates': dates}).eq('id', id);

  static Future<void> updateSubscriptionQuantity(String id, double qty) =>
      client.from('mk_subscriptions').update({'quantity_l': qty}).eq('id', id);

  /// One-time instant order
  static Future<void> placeOrder({
    required String supplierId,
    required String productId,
    required double qty,
    required DateTime date,
    String slot = 'morning_5_8',
    required String address,
    String? instructions,
    String paymentMode = 'cash',
  }) async {
    await client.from('mk_orders').insert({
      'customer_id': uid,
      'supplier_id': supplierId,
      'product_id': productId,
      'quantity_l': qty,
      'delivery_date': iso(date),
      'slot': slot,
      'amount': 0,
      'address': address,
      'instructions': instructions,
      'payment_mode': paymentMode,
    });
  }

  static Future<List<Json>> myOrders() async => List<Json>.from(await client
      .from('mk_orders')
      .select('*, products:mk_products(milk_type), supplier_profiles:mk_supplier_profiles(shop_name, village, profiles:mk_profiles(name, phone))')
      .eq('customer_id', uid)
      .order('delivery_date', ascending: false)
      .limit(60));

  static Future<void> fileComplaint({
    required String orderId,
    required String issueType,
    required String issue,
    String? photoUrl,
  }) =>
      client.from('mk_complaints').insert({
        'order_id': orderId,
        'customer_id': uid,
        'issue_type': issueType,
        'issue': issue,
        'photo_url': photoUrl,
      });

  static Future<void> addReview({
    required String supplierId,
    required int rating,
    String? comment,
  }) =>
      client.from('mk_reviews').upsert({
        'customer_id': uid,
        'supplier_id': supplierId,
        'rating': rating,
        'comment': comment,
      });

  static Future<List<Json>> supplierReviews(String supplierId) async =>
      List<Json>.from(await client
          .from('mk_reviews')
          .select('*, customer:mk_profiles(name, photo_url)')
          .eq('supplier_id', supplierId)
          .order('created_at', ascending: false)
          .limit(20));

  // ---------- Supplier / Farmer ----------
  static Future<Json> mySupplier() =>
      client.from('mk_supplier_profiles').select('*, profiles:mk_profiles(name, phone, photo_url)').eq('user_id', uid).single();

  static Future<void> updateSupplierProfile({
    String? shopName,
    String? about,
    String? village,
    String? upiId,
    String? bankAccountNo,
    String? bankIfsc,
    String? fssaiNo,
    List<String>? deliverySlots,
    List<String>? servicePincodes,
  }) async {
    final Map<String, dynamic> updates = {};
    if (shopName != null) updates['shop_name'] = shopName;
    if (about != null) updates['about'] = about;
    if (village != null) updates['village'] = village;
    if (upiId != null) updates['upi_id'] = upiId;
    if (bankAccountNo != null) updates['bank_account_no'] = bankAccountNo;
    if (bankIfsc != null) updates['bank_ifsc'] = bankIfsc;
    if (fssaiNo != null) updates['fssai_no'] = fssaiNo;
    if (deliverySlots != null) updates['delivery_slots'] = deliverySlots;

    if (updates.isNotEmpty) {
      await client.from('mk_supplier_profiles').update(updates).eq('user_id', uid);
    }
  }

  static Future<List<Json>> myProducts(String supplierId) async => List<Json>.from(await client
      .from('mk_products')
      .select()
      .eq('supplier_id', supplierId)
      .order('created_at'));

  static Future<void> addProduct({
    required String supplierId,
    required String type,
    required double price,
    required double dailyQty,
    double? fatPercent,
    double? snfPercent,
    String source = 'own_cattle',
    String processing = 'raw',
    double minOrder = 0.5,
    double deliveryCharge = 0,
  }) =>
      client.from('mk_products').insert({
        'supplier_id': supplierId,
        'milk_type': type,
        'price_per_litre': price,
        'daily_quantity_l': dailyQty,
        'fat_percent': fatPercent,
        'snf_percent': snfPercent,
        'source': source,
        'processing': processing,
        'min_order_l': minOrder,
        'delivery_charge': deliveryCharge,
      });

  static Future<void> setProductAvailable(String id, bool v) =>
      client.from('mk_products').update({'available': v}).eq('id', id);

  static Future<List<Json>> todayOrders(String supplierId, DateTime date) async {
    await client.rpc('mk_generate_orders_for_date', params: {'d': iso(date)});
    return List<Json>.from(await client
        .from('mk_orders')
        .select('*, customer:mk_profiles!customer_id(name, phone, photo_url), products:mk_products(milk_type), payments:mk_payments(id, amount, method)')
        .eq('supplier_id', supplierId)
        .eq('delivery_date', iso(date))
        .order('created_at'));
  }

  static Future<void> markOrder(String id, String status, num qty) => client
      .from('mk_orders')
      .update({'status': status, 'delivered_quantity': status == 'delivered' ? qty : 0}).eq('id', id);

  static Future<void> recordPayment(String orderId, num amount, String method) =>
      client.from('mk_payments').insert({'order_id': orderId, 'amount': amount, 'method': method});

  // ---------- Admin ----------
  static Future<Map<String, dynamic>> adminStats() async {
    final customers = await client.from('mk_profiles').select('id').eq('role', 'customer');
    final suppliers = await client.from('mk_profiles').select('id').eq('role', 'supplier');
    final subs = await client.from('mk_subscriptions').select('id').eq('status', 'active');
    final complaints = await client.from('mk_complaints').select('id').eq('resolution_status', 'open');

    return {
      'customers': (customers as List).length,
      'suppliers': (suppliers as List).length,
      'active_subs': (subs as List).length,
      'open_complaints': (complaints as List).length,
    };
  }

  static Future<List<Json>> pendingSuppliers() async => List<Json>.from(await client
      .from('mk_supplier_profiles')
      .select('*, profiles:mk_profiles(name, phone, photo_url)')
      .eq('verification_status', 'pending'));

  static Future<void> setVerification(String supplierId, String status, [String? reason]) =>
      client.rpc('mk_set_supplier_verification', params: {
        'p_supplier': supplierId,
        'p_status': status,
        'p_reason': reason,
      });

  static Future<List<Json>> complaints() async => List<Json>.from(await client
      .from('mk_complaints')
      .select('*, customer:mk_profiles!customer_id(name, phone), orders:mk_orders(delivery_date, quantity_l, amount)')
      .order('created_at', ascending: false));

  static Future<void> resolveComplaint(String id, [String? adminNotes]) =>
      client.from('mk_complaints').update({
        'resolution_status': 'resolved',
        'admin_notes': adminNotes,
      }).eq('id', id);

  static Future<List<Json>> allUsers({String? query}) async {
    var filter = client.from('mk_profiles').select();
    if (query != null && query.isNotEmpty) {
      filter = filter.ilike('name', '%$query%');
    }
    final res = await filter.order('created_at', ascending: false);
    return List<Json>.from(res);
  }

  static Future<void> setBlockUser(String userId, bool isBlocked) =>
      client.from('mk_profiles').update({'is_blocked': isBlocked}).eq('id', userId);
}

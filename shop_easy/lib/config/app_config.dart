//Cấu hình & Tiện ích
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';

// ==================== 1. CÁC BIẾN TRẠNG THÁI TOÀN CỤC ====================
final ValueNotifier<String> appLanguage = ValueNotifier<String>('vi');
final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier<ThemeMode>(
  ThemeMode.light,
);
final ValueNotifier<double> appFontSize = ValueNotifier<double>(16);

// Tỷ giá quy đổi từ Đô la Mỹ (USD) sang Việt Nam Đồng (VNĐ)
const double usdToVndRate = 25000;

// Bật/tắt chế độ tự động quy đổi giá USD (từ API) sang VNĐ khi hiển thị
final ValueNotifier<bool> convertUsdToVnd = ValueNotifier<bool>(true);

bool soundEnabled = true;
bool notificationEnabled = true;

const String _settingsStorageKey = 'shopeasy_app_settings';

Future<void> loadAppSettings() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsStorageKey);
    if (raw == null || raw.isEmpty) return;

    final map = jsonDecode(raw) as Map<String, dynamic>;
    appLanguage.value = (map['language'] ?? 'vi').toString();
    appThemeMode.value = (map['darkMode'] == true)
        ? ThemeMode.dark
        : ThemeMode.light;
    appFontSize.value = (map['fontSize'] as num? ?? 16).toDouble();
    convertUsdToVnd.value = map['convertUsdToVnd'] ?? true;
    soundEnabled = map['soundEnabled'] ?? true;
    notificationEnabled = map['notificationEnabled'] ?? true;
  } catch (_) {}
}

Future<void> saveAppSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final data = {
    'language': appLanguage.value,
    'darkMode': appThemeMode.value == ThemeMode.dark,
    'fontSize': appFontSize.value,
    'convertUsdToVnd': convertUsdToVnd.value,
    'soundEnabled': soundEnabled,
    'notificationEnabled': notificationEnabled,
  };
  await prefs.setString(_settingsStorageKey, jsonEncode(data));
}

// ==================== 2. QUẢN LÝ & LƯU TRỮ TÀI KHOẢN ====================
final Map<String, String> accounts = {};
const String _accountsStorageKey = 'shopeasy_registered_accounts';

Future<void> loadRegisteredAccounts() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsStorageKey);
    if (raw == null || raw.isEmpty) return;

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      accounts
        ..clear()
        ..addAll(
          decoded.map(
            (key, value) =>
                MapEntry(key.toString().toLowerCase(), value.toString()),
          ),
        );
    }
  } catch (_) {
    accounts.clear();
  }
}

Future<void> saveRegisteredAccounts() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_accountsStorageKey, jsonEncode(accounts));
}

// ==================== 3. QUẢN LÝ ĐƠN HÀNG CHO DASHBOARD ====================
class AppOrder {
  final String code;
  final String customer;
  final String date;
  final String status;
  final double totalVnd;
  final int colorValue;

  const AppOrder({
    required this.code,
    required this.customer,
    required this.date,
    required this.status,
    required this.totalVnd,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'customer': customer,
    'date': date,
    'status': status,
    'totalVnd': totalVnd,
    'colorValue': colorValue,
  };

  factory AppOrder.fromJson(Map<String, dynamic> json) => AppOrder(
    code: json['code'] ?? '',
    customer: json['customer'] ?? '',
    date: json['date'] ?? '',
    status: json['status'] ?? '',
    totalVnd: (json['totalVnd'] as num? ?? 0).toDouble(),
    colorValue: (json['colorValue'] as num? ?? 0xFF159B72).toInt(),
  );
}

const List<AppOrder> _defaultOrders = [
  AppOrder(
    code: '#DH1028',
    customer: 'Nguyễn Minh Anh',
    date: '02/11/2026',
    status: 'Đã giao',
    totalVnd: 1250000,
    colorValue: 0xFF159B72,
  ),
  AppOrder(
    code: '#DH1027',
    customer: 'Trần Hoàng Nam',
    date: '02/11/2026',
    status: 'Đang giao',
    totalVnd: 890000,
    colorValue: 0xFF2878D0,
  ),
  AppOrder(
    code: '#DH1026',
    customer: 'Lê Thu Hà',
    date: '01/11/2026',
    status: 'Chờ xác nhận',
    totalVnd: 2190000,
    colorValue: 0xFFE18A25,
  ),
  AppOrder(
    code: '#DH1025',
    customer: 'Phạm Quốc Bảo',
    date: '01/11/2026',
    status: 'Đã hủy',
    totalVnd: 450000,
    colorValue: 0xFFD94B4B,
  ),
];

final ValueNotifier<List<AppOrder>> recentOrders =
    ValueNotifier<List<AppOrder>>([..._defaultOrders]);
const String _ordersStorageKey = 'shopeasy_recent_orders';

Future<void> loadOrders() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_ordersStorageKey);
    if (raw == null || raw.isEmpty) return;

    final List decoded = jsonDecode(raw);
    recentOrders.value = decoded.map((e) => AppOrder.fromJson(e)).toList();
  } catch (_) {
    recentOrders.value = [..._defaultOrders];
  }
}

Future<void> addNewOrder(
  double totalVnd, {
  String customer = 'Khách hàng',
}) async {
  final now = DateTime.now();
  final dateStr =
      '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  final nextNumber = 1025 + recentOrders.value.length;

  final newOrder = AppOrder(
    code: '#DH$nextNumber',
    customer: customer,
    date: dateStr,
    status: 'Đang xử lý',
    totalVnd: totalVnd,
    colorValue: 0xFF2878D0,
  );

  recentOrders.value = [newOrder, ...recentOrders.value];

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _ordersStorageKey,
    jsonEncode(recentOrders.value.map((e) => e.toJson()).toList()),
  );
}

// ==================== 4. HÀM DỊCH ĐA NGÔN NGỮ & THÔNG BÁO ====================
String tr(String vi, String en, String zh) {
  switch (appLanguage.value) {
    case 'en':
      return en;
    case 'zh':
      return zh;
    default:
      return vi;
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

// ==================== 5. HÀM CHUYỂN ĐỔI TIỀN TỆ & HÌNH ẢNH ====================
// Quy đổi chính xác sang VNĐ dựa trên thuộc tính isUsd của sản phẩm
double toVnd(ShopProduct product) {
  return product.isUsd ? product.price * usdToVndRate : product.price;
}

// Định dạng chuỗi tiền tệ VNĐ có dấu chấm phân cách hàng nghìn
String formatVnd(double vndValue) {
  return '${vndValue.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
}

// Định dạng giá theo đơn vị gốc của sản phẩm và chế độ quy đổi hiện tại
String formatPrice(double amount, {required bool isUsd}) {
  if (amount == 0) return '0 đ';
  if (!isUsd) {
    return formatVnd(amount);
  }
  if (convertUsdToVnd.value) {
    return formatVnd(amount * usdToVndRate);
  }
  return '\$${amount.toStringAsFixed(2)}';
}

String formatProductPrice(ShopProduct product) {
  return formatPrice(product.price, isUsd: product.isUsd);
}

String formatProductOldPrice(ShopProduct product) {
  return formatPrice(product.oldPrice, isUsd: product.isUsd);
}

Widget buildProductImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (path.startsWith('http')) {
    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Center(child: Icon(Icons.image_not_supported, size: 40)),
      ),
    );
  }
  return Image.asset(
    path,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(child: Icon(Icons.image_not_supported, size: 40)),
    ),
  );
}

Widget languageSelector() {
  return ValueListenableBuilder<String>(
    valueListenable: appLanguage,
    builder: (context, language, child) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {
              appLanguage.value = 'vi';
              saveAppSettings();
            },
            child: Text(
              'VI',
              style: TextStyle(
                fontWeight: language == 'vi'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              appLanguage.value = 'en';
              saveAppSettings();
            },
            child: Text(
              'EN',
              style: TextStyle(
                fontWeight: language == 'en'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              appLanguage.value = 'zh';
              saveAppSettings();
            },
            child: Text(
              '中文',
              style: TextStyle(
                fontWeight: language == 'zh'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      );
    },
  );
}

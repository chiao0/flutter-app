import 'package:flutter/foundation.dart' show kIsWeb;

// 只在非網頁平台導入 health 套件
export 'package:health/health.dart' if (dart.library.js) 'web_health_stub.dart';

// 如果當前平台是網頁，則使用 HealthFactory 和 HealthDataPoint 的佔位實現
class HealthFactory {
  Future<bool> requestAuthorization(List<dynamic> types) async {
    return false;
  }

  Future<List<dynamic>> getHealthDataFromTypes(
      DateTime startDate, DateTime endDate, List<dynamic> types) async {
    return [];
  }
}

class HealthDataPoint {
  final dynamic value;
  final DateTime dateFrom;
  final DateTime dateTo;

  HealthDataPoint({required this.value, required this.dateFrom, required this.dateTo});
}

enum HealthDataType {
  BLOOD_PRESSURE_SYSTOLIC,
  BLOOD_PRESSURE_DIASTOLIC,
  HEART_RATE,
}
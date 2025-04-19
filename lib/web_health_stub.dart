// 在網頁平台上使用的 health 套件佔位實現
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
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// 條件導入，避免在網頁平台上出錯
import 'health_imports.dart';

class BloodPressureScreen extends StatefulWidget {
  @override
  _BloodPressureScreenState createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen> {
  final List<String> timePeriods = [
    '起床', '早餐前', '早餐後', '午餐前', '午餐後', '晚餐前', '晚餐後', '睡覺前'
  ];
  String? selectedPeriod;
  DateTime selectedDateTime = DateTime.now();
  final TextEditingController systolicController = TextEditingController();
  final TextEditingController diastolicController = TextEditingController();
  final TextEditingController pulseController = TextEditingController();

  // 健康數據相關變數
  dynamic health;
  bool isLoading = false;
  bool isWebPlatform = false;

  @override
  void initState() {
    super.initState();
    // 檢查是否為網頁平台
    isWebPlatform = kIsWeb;

    // 僅在非網頁平台上初始化 health
    if (!isWebPlatform) {
      try {
        initializeHealth();
      } catch (e) {
        print("Health package initialization failed: $e");
      }
    }
  }

  void initializeHealth() {
    if (!kIsWeb) {
      health = HealthFactory();
    }
  }

  Future<void> _pickDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _showValueAlert(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("輸入錯誤"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("重新輸入"),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchDataFromGoogleFit() async {
    // 在網頁平台上顯示提示並返回
    if (isWebPlatform) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Fit 功能僅在 Android 和 iOS 設備上可用')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // 請求權限
      final types = [
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.HEART_RATE,
      ];

      bool requested = await health.requestAuthorization(types);

      if (!requested) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('未獲得健康數據訪問權限')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // 獲取過去24小時的健康數據
      final now = DateTime.now();
      final before = now.subtract(Duration(hours: 24));

      // 獲取收縮壓數據
      List<HealthDataPoint> systolicPoints = await health.getHealthDataFromTypes(
          before,
          now,
          [HealthDataType.BLOOD_PRESSURE_SYSTOLIC]
      );

      // 獲取舒張壓數據
      List<HealthDataPoint> diastolicPoints = await health.getHealthDataFromTypes(
          before,
          now,
          [HealthDataType.BLOOD_PRESSURE_DIASTOLIC]
      );

      // 獲取心率數據
      List<HealthDataPoint> heartRatePoints = await health.getHealthDataFromTypes(
          before,
          now,
          [HealthDataType.HEART_RATE]
      );

      bool hasData = false;

      // 填入最新的數據（如果有）
      if (systolicPoints.isNotEmpty) {
        // 按時間排序並取最新的一筆
        systolicPoints.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        final systolic = systolicPoints.first.value.toString().split('.')[0]; // 取整數部分
        setState(() {
          systolicController.text = systolic;
        });
        hasData = true;
      }

      if (diastolicPoints.isNotEmpty) {
        diastolicPoints.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        final diastolic = diastolicPoints.first.value.toString().split('.')[0]; // 取整數部分
        setState(() {
          diastolicController.text = diastolic;
        });
        hasData = true;
      }

      if (heartRatePoints.isNotEmpty) {
        heartRatePoints.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
        final heartRate = heartRatePoints.first.value.toString().split('.')[0]; // 取整數部分
        setState(() {
          pulseController.text = heartRate;
        });
        hasData = true;
      }

      if (hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已從 Google Fit 填入最新數據')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Fit 中未找到相關健康數據')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('獲取健康數據失敗: ${e.toString()}')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _saveBloodPressureRecord() async {
    final int? systolic = int.tryParse(systolicController.text);
    final int? diastolic = int.tryParse(diastolicController.text);
    final int? pulse = int.tryParse(pulseController.text);

    if (systolic == null || diastolic == null || pulse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("請輸入有效的數字")),
      );
      return;
    }

    if (selectedPeriod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("請選擇時段")),
      );
      return;
    }

    if (systolic < 70 || systolic > 250) {
      _showValueAlert("收縮壓應介於 70 到 250 mmHg");
      return;
    }
    if (diastolic < 40 || diastolic > 150) {
      _showValueAlert("舒張壓應介於 40 到 150 mmHg");
      return;
    }
    if (pulse < 30 || pulse > 200) {
      _showValueAlert("脈搏應介於 30 到 200 bpm");
      return;
    }
    if (systolic <= diastolic) {
      _showValueAlert("收縮壓應大於舒張壓");
      return;
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("請先登入")),
      );
      return;
    }
    String uid = currentUser.uid;

    CollectionReference bpRecords =
    FirebaseFirestore.instance.collection('blood_pressure_records');

    try {
      String formattedId =
      DateFormat('yyyyMMdd_HHmmssSSS').format(selectedDateTime);

      await bpRecords.doc(formattedId).set({
        'systolic': systolic,
        'diastolic': diastolic,
        'pulse': pulse,
        'measurement_date':
        DateFormat('yyyy/MM/dd HH:mm').format(selectedDateTime),
        'timestamp': selectedDateTime,
        'period': selectedPeriod,
        'user_id': uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("血壓記錄已儲存")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("儲存失敗: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('血壓記錄')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _pickDateTime(context),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  border:
                  Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "選擇日期與時間: ${DateFormat('yyyy/MM/dd HH:mm').format(selectedDateTime)}",
                      style: TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPeriod,
              decoration: InputDecoration(labelText: '選擇時段'),
              items: timePeriods.map((String period) {
                return DropdownMenuItem<String>(
                  value: period,
                  child: Text(period),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedPeriod = newValue;
                });
              },
            ),
            SizedBox(height: 20),
            TextField(
              controller: systolicController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '收縮壓 SYS (mmHg)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: diastolicController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '舒張壓 DIA (mmHg)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: pulseController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '脈搏 PULSE (bpm)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            if (isWebPlatform)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Google Fit 功能僅在 Android 和 iOS 設備上可用',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              )
            else
              ElevatedButton(
                onPressed: isLoading ? null : _fetchDataFromGoogleFit,
                child: isLoading
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('正在獲取數據...'),
                  ],
                )
                    : Text('從 Google Fit 自動填入數據'),
              ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: Text('取消', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: _saveBloodPressureRecord,
                  child: Text('儲存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
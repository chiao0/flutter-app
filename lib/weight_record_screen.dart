import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WeightRecordScreen extends StatefulWidget {
  @override
  _WeightRecordScreenState createState() => _WeightRecordScreenState();
}

class _WeightRecordScreenState extends State<WeightRecordScreen> {
  DateTime selectedDateTime = DateTime.now();
  final TextEditingController weightController = TextEditingController();

  /// 選擇日期 + 時間
  Future<void> _pickDateTime(BuildContext context) async {
    // 先選擇日期
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      // 選擇時間
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          // 合併日期與時間
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

  /// 顯示錯誤提示
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

  Future<void> _saveWeightRecord() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("請先登入")));
      return;
    }

    // 檢查體重值是否有效
    if (weightController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("請輸入體重")));
      return;
    }

    double? weight = double.tryParse(weightController.text);
    if (weight == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("請輸入有效的數字")));
      return;
    }

    // 離譜值檢查
    if (weight < 20 || weight > 300) {
      _showValueAlert("體重應介於 20 到 300 公斤");
      return;
    }

    String uid = currentUser.uid;
    CollectionReference weightRecords = FirebaseFirestore.instance.collection('weight_records');

    try {
      // 使用與血壓頁面相同的 ID 格式
      String formattedId = DateFormat('yyyyMMdd_HHmmssSSS').format(selectedDateTime);

      await weightRecords.doc(formattedId).set({
        'weight': weight,
        'measurement_date': DateFormat('yyyy/MM/dd HH:mm').format(selectedDateTime),
        'timestamp': selectedDateTime,  // 新增時間戳記欄位，方便排序和查詢
        'user_id': uid,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("體重記錄已儲存")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("儲存失敗: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('體重記錄')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期 + 時間選擇 - 整個區域可點擊
            InkWell(
              onTap: () => _pickDateTime(context),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
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
            SizedBox(height: 20),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '體重 (kg)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: Text("取消", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: _saveWeightRecord,
                  child: Text("儲存"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BloodSugarScreen extends StatefulWidget {
  @override
  _BloodSugarScreenState createState() => _BloodSugarScreenState();
}

class _BloodSugarScreenState extends State<BloodSugarScreen> {
  final List<String> timePeriods = [
    '起床', '早餐前', '早餐後', '午餐前', '午餐後', '晚餐前', '晚餐後', '睡覺前'
  ];
  String? selectedPeriod;
  DateTime selectedDateTime = DateTime.now();

  final TextEditingController sugarController = TextEditingController();
  final TextEditingController hba1cController = TextEditingController();
  bool isMgDl = true;

  @override
  void initState() {
    super.initState();
    sugarController.addListener(() => setState(() {}));
    hba1cController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    sugarController.dispose();
    hba1cController.dispose();
    super.dispose();
  }

  void _toggleUnit() {
    setState(() {
      if (sugarController.text.isNotEmpty) {
        double? value = double.tryParse(sugarController.text);
        if (value != null) {
          if (isMgDl) {
            value = value / 18.0;
          } else {
            value = value * 18.0;
          }
          sugarController.text = value.toStringAsFixed(2);
        }
      }
      isMgDl = !isMgDl;
    });
  }

  double _estimateHbA1c(double sugarMgDl) {
    return (sugarMgDl + 46.7) / 28.7;
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

  Future<void> _saveBloodSugarRecord() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("請先登入")),
      );
      return;
    }

    // ✅ 檢查是否選擇時段
    if (selectedPeriod == null || selectedPeriod!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("請選擇時段")),
      );
      return;
    }

    double? sugarValue = double.tryParse(sugarController.text);
    if (sugarValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("請輸入有效的血糖數值")),
      );
      return;
    }

    double sugarMgDl = isMgDl ? sugarValue : sugarValue * 18;
    if (sugarMgDl < 20 || sugarMgDl > 600) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("血糖數值超出合理範圍（20~600 mg/dL）")),
      );
      return;
    }

    double estimatedHbA1c = _estimateHbA1c(sugarMgDl);
    double? userHbA1c = double.tryParse(hba1cController.text);

    if (userHbA1c != null) {
      if ((userHbA1c - estimatedHbA1c).abs() > 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("輸入的糖化血色素與血糖值不符，請檢查數值是否正確")),
        );
        return;
      }
    }

    String uid = currentUser.uid;
    CollectionReference bsRecords =
    FirebaseFirestore.instance.collection('blood_sugar_records');

    try {
      // 使用與血壓頁面相同的 ID 格式
      String formattedId = DateFormat('yyyyMMdd_HHmmssSSS').format(selectedDateTime);

      await bsRecords.doc(formattedId).set({
        'blood_sugar': sugarMgDl,
        'blood_sugar_unit': isMgDl ? 'mg/dL' : 'mmol/L',
        'hba1c': userHbA1c ?? double.parse(estimatedHbA1c.toStringAsFixed(2)),
        'hba1c_estimated': userHbA1c == null,
        'measurement_date': DateFormat('yyyy/MM/dd HH:mm').format(selectedDateTime),
        'timestamp': selectedDateTime,  // 新增時間戳記欄位
        'period': selectedPeriod,
        'user_id': uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("血糖記錄已儲存")),
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
    double? sugarValue = double.tryParse(sugarController.text);
    double estimatedHbA1c = sugarValue != null
        ? _estimateHbA1c(isMgDl ? sugarValue : sugarValue * 18)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text('血糖記錄')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期時間選擇
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
            SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedPeriod,
              decoration: InputDecoration(labelText: '選擇時段'),
              items: timePeriods.map((String period) {
                return DropdownMenuItem<String>(value: period, child: Text(period));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedPeriod = newValue;
                });
              },
            ),
            SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: sugarController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: '血糖值',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Text(isMgDl ? 'mg/dL' : 'mmol/L'),
                IconButton(
                  icon: Icon(Icons.swap_horiz),
                  onPressed: _toggleUnit,
                ),
              ],
            ),
            SizedBox(height: 20),

            TextField(
              controller: hba1cController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: '糖化血色素（可選填）',
                border: OutlineInputBorder(),
              ),
            ),

            if (hba1cController.text.isEmpty && sugarValue != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '估算糖化血色素為 ${estimatedHbA1c.toStringAsFixed(2)} %',
                  style: TextStyle(color: Colors.grey),
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
                  onPressed: () {
                    if (hba1cController.text.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text("確認糖化血色素"),
                            content: Text(
                                "估算的糖化血色素為 ${estimatedHbA1c.toStringAsFixed(2)}%。是否儲存此數據？"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("取消"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _saveBloodSugarRecord();
                                },
                                child: Text("儲存"),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      _saveBloodSugarRecord();
                    }
                  },
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

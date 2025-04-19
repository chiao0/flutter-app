import 'package:flutter/material.dart';

class CompanionHealthDataScreen extends StatelessWidget {
  final String companionName;

  CompanionHealthDataScreen({required this.companionName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$companionName 的健康數據")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("血糖: 120 mg/dL", style: TextStyle(fontSize: 20)),
            Text("血壓: 130/85 mmHg", style: TextStyle(fontSize: 20)),
            Text("飲食紀錄: 早餐 - 燕麥", style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

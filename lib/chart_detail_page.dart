import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChartDetailPage extends StatelessWidget {
  final String title;

  ChartDetailPage({required this.title});

  // 定義不同類別的 y 軸單位
  final Map<String, String> unitMap = {
    "血糖": "mg/dL",
    "血壓": "mmHg",
    "心跳": "bpm",
    "體重": "kg",
  };

  @override
  Widget build(BuildContext context) {
    // 獲取對應的 y 軸單位
    String unit = unitMap[title] ?? "";

    return Scaffold(
      appBar: AppBar(title: Text("$title 分析")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("$title 數據變化 ($unit)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection(title).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  // 將 Firebase 數據轉換為 FlSpot
                  final data = snapshot.data!.docs;
                  List<FlSpot> spots = data.asMap().entries.map((entry) {
                    int index = entry.key;
                    double value = (entry.value['value'] as num).toDouble();
                    return FlSpot(index.toDouble(), value);
                  }).toList();

                  return LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.blue,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          axisNameWidget: Text("數值 ($unit)", style: TextStyle(fontSize: 14)),
                          sideTitles: SideTitles(showTitles: true),
                        ),
                        bottomTitles: AxisTitles(
                          axisNameWidget: Text("時間", style: TextStyle(fontSize: 14)),
                          sideTitles: SideTitles(showTitles: true),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

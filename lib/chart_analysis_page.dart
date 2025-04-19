import 'package:flutter/material.dart';
import 'chart_detail_page.dart';

class ChartAnalysisPage extends StatelessWidget {
  final List<Map<String, String>> charts = [
    {"title": "血糖", "description": "查看血糖數據圖表"},
    {"title": "血壓", "description": "查看血壓數據圖表"},
    {"title": "心跳", "description": "查看血壓數據圖表"},
    {"title": "體重", "description": "查看體重變化圖表"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("圖表分析")),
      body: ListView.builder(
        itemCount: charts.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text(charts[index]["title"]!),
              subtitle: Text(charts[index]["description"]!),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChartDetailPage(title: charts[index]["title"]!),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

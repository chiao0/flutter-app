import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleFitDataScreen extends StatefulWidget {
  @override
  _GoogleFitDataScreenState createState() => _GoogleFitDataScreenState();
}

class _GoogleFitDataScreenState extends State<GoogleFitDataScreen> {
  String stepResult = "尚未讀取";
  String heartResult = "尚未讀取";

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/fitness.activity.read',
      'https://www.googleapis.com/auth/fitness.heart_rate.read',
    ],
  );

  Future<void> _fetchData() async {
    try {
      final account = await _googleSignIn.signIn();
      final auth = await account?.authentication;
      final accessToken = auth?.accessToken;

      if (accessToken != null) {
        final stepData = await fetchGoogleFitData(
          accessToken,
          "com.google.step_count.delta",
        );
        final heartData = await fetchGoogleFitData(
          accessToken,
          "com.google.heart_rate.bpm",
        );

        setState(() {
          stepResult = stepData;
          heartResult = heartData;
        });
      }
    } catch (e) {
      setState(() {
        stepResult = "讀取失敗：$e";
        heartResult = "讀取失敗：$e";
      });
    }
  }

  Future<String> fetchGoogleFitData(String accessToken, String dataTypeName) async {
    final now = DateTime.now();
    final startTime = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endTime = now.millisecondsSinceEpoch;

    final url = Uri.parse('https://www.googleapis.com/fitness/v1/users/me/dataset:aggregate');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "aggregateBy": [
          {"dataTypeName": dataTypeName}
        ],
        "bucketByTime": {"durationMillis": 86400000},
        "startTimeMillis": startTime,
        "endTimeMillis": endTime,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final buckets = data['bucket'] as List;
      if (buckets.isNotEmpty) {
        final dataset = buckets.first['dataset'][0]['point'];
        if (dataset.isNotEmpty) {
          return dataset.first['value'][0]['fpVal'].toString();
        }
      }
      return "無數據";
    } else {
      return "請求錯誤：${response.statusCode}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Fit 數據')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _fetchData,
              child: Text('從 Google Fit 讀取數據'),
            ),
            SizedBox(height: 20),
            Text("今日步數：$stepResult", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("今日心率：$heartResult", style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

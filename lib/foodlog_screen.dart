import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // kIsWeb 需要這個
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 只有在非 Web 環境才導入 dart:io
import 'dart:io' show File;

class FoodLogScreen extends StatefulWidget {
  @override
  _FoodLogScreenState createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  Uint8List? _webImageBytes; // Web 版圖片
  XFile? _imageFile; // 手機端圖片
  final ImagePicker _picker = ImagePicker();
  DateTime _selectedDateTime = DateTime.now();

  /// 選擇圖片 (適用 Web & 手機)
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      if (kIsWeb) {
        // Web 版: 讀取 Uint8List
        var webImage = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = webImage;
          _imageFile = pickedFile;
        });
      } else {
        // 手機版: 直接使用 XFile
        setState(() {
          _imageFile = pickedFile;
        });
      }
    }
  }

  /// 上傳圖片到 Firebase
  Future<void> _uploadToFirebase() async {
    if (_imageFile == null) return;
    try {
      String fileName = '${_selectedDateTime.toIso8601String()}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child('food_images/$fileName');

      if (kIsWeb) {
        // Web 版: 使用 putData (因為 Web 不能用 File)
        await storageRef.putData(_webImageBytes!);
      } else {
        // 手機版: 使用 putFile (轉換成 File)
        await storageRef.putFile(File(_imageFile!.path));
      }

      String imageUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('food_logs').add({
        'dateTime': _selectedDateTime.toIso8601String(),
        'imageUrl': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上傳成功！')),
      );

      setState(() {
        _webImageBytes = null;
        _imageFile = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上傳失敗: $e')),
      );
    }
  }

  /// 選擇日期和時間
  Future<void> _pickDateTime() async {
    // 選擇日期
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      // 選擇時間
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          // 合併日期和時間
          _selectedDateTime = DateTime(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('飲食紀錄')),
      body: Column(
        children: [
          // 日期 + 時間選擇按鈕
          TextButton(
            onPressed: _pickDateTime,
            child: Text(
              '選擇日期與時間: ${_selectedDateTime.year}/${_selectedDateTime.month.toString().padLeft(2, '0')}/${_selectedDateTime.day.toString().padLeft(2, '0')} '
                  '${_selectedDateTime.hour}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
            ),
          ),

          // 顯示選擇的圖片
          _imageFile == null
              ? Text('尚未選擇圖片')
              : kIsWeb
              ? Image.memory(_webImageBytes!, height: 200, fit: BoxFit.cover) // Web 使用 Image.memory
              : Image.file(File(_imageFile!.path), height: 200, fit: BoxFit.cover), // 手機使用 Image.file

          // 拍照 & 圖庫選擇圖片
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.camera_alt),
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              IconButton(
                icon: Icon(Icons.photo_library),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),

          // 上傳按鈕
          ElevatedButton(
            onPressed: _uploadToFirebase,
            child: Text('上傳'),
          ),
        ],
      ),
    );
  }
}
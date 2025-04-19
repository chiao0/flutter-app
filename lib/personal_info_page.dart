import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 用於數字輸入限制
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart'; // 用於檔案儲存
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({Key? key}) : super(key: key);

  @override
  _PersonalInfoPageState createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  // 初始顯示預設值，待從 Firestore 載入後更新
  String name = '王小明';
  String gender = '男';
  String age = '28'; // 若註冊時存入的是生日(dob)，這裡可視需求改為顯示生日
  String bloodType = 'O';
  String heightValue = '175';
  String weightValue = '68';

  // 頭像相關
  File? _avatarImage;
  final String avatarFileName = 'test.png';

  @override
  void initState() {
    super.initState();
    _loadAvatar();
    _loadUserInfo();
  }

  // 讀取已存儲的圖片
  Future<void> _loadAvatar() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final file = File('$path/$avatarFileName');

      if (await file.exists()) {
        setState(() {
          _avatarImage = file;
        });
      }
    } catch (e) {
      print('載入頭像失敗: $e');
    }
  }

  // 從 shared_preferences 讀取 uid，並從 Firestore 載入使用者資料
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('uid');
    if (uid != null && uid.isNotEmpty) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(uid)
          .get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          name = data['name'] ?? name;
          gender = data['gender'] ?? gender;
          // 假設在註冊時存入的是生日，這裡顯示生日；你也可以計算年齡
          age = data['dob'] ?? age;
          bloodType = data['blood_type'] ?? bloodType;
          heightValue = data['height'] ?? heightValue;
          weightValue = data['weight'] ?? weightValue;
        });
      }
    }
  }

  // 以下為原有的編輯方法
  void _changePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File tempFile = File(pickedFile.path);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("預覽照片"),
          content: Image.file(tempFile, width: 200, height: 200),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final directory = await getApplicationDocumentsDirectory();
                  final path = directory.path;
                  final savedFile = await tempFile.copy('$path/$avatarFileName');

                  setState(() {
                    _avatarImage = savedFile;
                  });
                } catch (e) {
                  print('儲存頭像失敗: $e');
                }
                Navigator.pop(context);
              },
              child: const Text("確定"),
            ),
          ],
        ),
      );
    }
  }

  void editInfo(String field, String currentValue, Function(String) onSave) {
    TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('編輯 $field'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: '輸入新的 $field'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  void editNumericInfo(String field, String currentValue, Function(String) onSave) {
    TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('編輯 $field'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(hintText: '只輸入數字 (不含單位)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  void editBloodType(String currentValue, Function(String) onSave) {
    String selectedBloodType = currentValue;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('編輯血型'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return DropdownButton<String>(
                value: selectedBloodType,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedBloodType = newValue;
                    });
                  }
                },
                items: <String>['A', 'B', 'AB', 'O']
                    .map((String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                ))
                    .toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                onSave(selectedBloodType);
                Navigator.pop(context);
              },
              child: const Text('儲存'),
            ),
          ],
        );
      },
    );
  }

  Widget buildInfoRow(String label, String value, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('個人資訊', textAlign: TextAlign.center),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 顯示目前頭像
              CircleAvatar(
                radius: 60,
                backgroundImage: _avatarImage != null
                    ? FileImage(_avatarImage!)
                    : const AssetImage('assets/avatar.jpg') as ImageProvider,
              ),
              const SizedBox(height: 10),
              // 「更換照片」按鈕
              ElevatedButton(
                onPressed: _changePhoto,
                child: const Text("更換照片"),
              ),
              const SizedBox(height: 20),
              // 各項個人資料欄位
              buildInfoRow(
                '姓名',
                name,
                    () => editInfo('姓名', name, (value) {
                  setState(() => name = value);
                }),
              ),
              buildInfoRow(
                '性別',
                gender,
                    () => editInfo('性別', gender, (value) {
                  setState(() => gender = value);
                }),
              ),
              buildInfoRow(
                '年齡',
                age,
                    () => editNumericInfo('年齡', age, (value) {
                  setState(() => age = value);
                }),
              ),
              buildInfoRow(
                '血型',
                bloodType,
                    () => editBloodType(bloodType, (value) {
                  setState(() => bloodType = value);
                }),
              ),
              buildInfoRow(
                '身高',
                '$heightValue cm',
                    () => editNumericInfo('身高', heightValue, (value) {
                  setState(() => heightValue = value);
                }),
              ),
              buildInfoRow(
                '體重',
                '$weightValue kg',
                    () => editNumericInfo('體重', weightValue, (value) {
                  setState(() => weightValue = value);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: PersonalInfoPage(),
  ));
}

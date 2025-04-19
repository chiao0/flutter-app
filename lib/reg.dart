import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // 使用 FlutterFire CLI 生成的檔案
import 'package:flutter/gestures.dart';




class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // 輸入控制器
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _heightController = TextEditingController(); // 身高
  final TextEditingController _weightController = TextEditingController(); // 體重

  // 性別與血型選項
  String? selectedGender;
  String? selectedBloodType;
  bool _isPrivacyAccepted = false; // 隱私條款勾選狀態

  final List<String> genderOptions = ['男', '女', '不方便透露'];
  final List<String> bloodTypeOptions = ['A', 'B', 'AB', 'O', '不明'];

  // 密碼顯示/隱藏
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Firebase Authentication 與 Firestore 實例
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _registerUser() async {
    if (!_isPrivacyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("請先閱讀並勾選同意使用者隱私條款")),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        // 建立 Firebase Authentication 帳號
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        User? user = userCredential.user;
        if (user != null) {
          // 寄送電子郵件驗證信
          await user.sendEmailVerification();
          print("驗證郵件已寄出至 ${user.email}");

          // 將使用者其他資訊存入 Firestore 的 user_profile 集合（以使用者 uid 為文件 ID）
          await _firestore.collection('user_profile').doc(user.uid).set({
            'uid': user.uid,
            'email': _emailController.text.trim(),
            'name': _nameController.text.trim(),
            'dob': _dobController.text.trim(),
            'gender': selectedGender, // 性別
            'blood_type': selectedBloodType, // 血型
            'height': _heightController.text.trim(), // 身高
            'weight': _weightController.text.trim(), // 體重
            'created_at': FieldValue.serverTimestamp(),
          });

          // 顯示成功訊息（包括驗證信已寄出的訊息）
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("註冊成功，驗證信已寄出！請至信箱進行驗證")),
          );

          // 清除輸入欄位
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          _nameController.clear();
          _dobController.clear();
          _heightController.clear();
          _weightController.clear();
          setState(() {
            selectedGender = null;
            selectedBloodType = null;
          });

          // 註冊成功後跳轉到 home_page.dart（此處可依需求修改跳轉方式）
          Navigator.pushReplacementNamed(context, '/');
        }
      } on FirebaseAuthException catch (e) {
        print("FirebaseAuthException: ${e.code} - ${e.message}");
        String errorMessage = "註冊失敗";
        if (e.code == 'email-already-in-use') {
          errorMessage = "此電子郵件已被註冊";
        } else if (e.code == 'weak-password') {
          errorMessage = "密碼強度不足，請使用更強的密碼";
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        print("其他錯誤: ${e.toString()}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("註冊失敗: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("註冊")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 電子郵件
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "電子郵件"),
                validator: (value) {
                  if (value == null || value.isEmpty) return '請輸入電子郵件';
                  if (!RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return '請輸入有效的電子郵件';
                  }
                  return null;
                },
              ),
              // 密碼
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible, // 控制密碼是否顯示
                decoration: InputDecoration(
                  labelText: "密碼",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入密碼';
                  }
                  if (value.length < 8) {
                    return '密碼至少8個字符';
                  }
                  if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(value)) {
                    return '密碼只能包含英文與數字';
                  }
                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                    return '密碼需至少包含一個大寫英文字母';
                  }
                  if (!RegExp(r'[a-z]').hasMatch(value)) {
                    return '密碼需至少包含一個小寫英文字母';
                  }
                  return null;
                },
              ),

              // 確認密碼
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible, // 控制確認密碼顯示
                decoration: InputDecoration(
                  labelText: "確認密碼",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != _passwordController.text) return '密碼不匹配';
                  return null;
                },
              ),
              // 姓名
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "姓名"),
                validator: (value) {
                  if (value == null || value.isEmpty) return '請輸入姓名';
                  return null;
                },
              ),
              // 生日
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(labelText: "生日 (YYYY-MM-DD)"),
                validator: (value) {
                  if (value == null || value.isEmpty) return '請輸入生日';
                  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
                    return '請使用 YYYY-MM-DD 格式';
                  }
                  return null;
                },
              ),
              // 性別下拉選單
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(labelText: "性別"),
                items: genderOptions.map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedGender = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return '請選擇性別';
                  return null;
                },
              ),
              // 血型下拉選單
              DropdownButtonFormField<String>(
                value: selectedBloodType,
                decoration: const InputDecoration(labelText: "血型"),
                items: bloodTypeOptions.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedBloodType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return '請選擇血型';
                  return null;
                },
              ),
              // 身高
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: "身高 (cm)"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return '請輸入身高';
                  final height = double.tryParse(value);
                  if (height == null) return '請輸入數字';
                  if (height < 30 || height > 300) return '請輸入30-300之間的數值';
                  return null;
                },
              ),
              // 體重
              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(labelText: "體重 (kg)"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return '請輸入體重';
                  final weight = double.tryParse(value);
                  if (weight == null) return '請輸入數字';
                  if (weight < 20 || weight > 500) return '請輸入20-500之間的數值';
                  return null;
                },
              ),
              CheckboxListTile(
                title: RichText(
                  text: TextSpan(
                    text: "我同意 ",
                    style: const TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: "使用者隱私條款",
                        style: const TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("使用者隱私條款"),
                                content: const SingleChildScrollView(
                                  child: Text(
                                    '''1. 引言
歡迎使用本應用程式（以下稱「本 APP」）。我們非常重視您的隱私權，並致力於保護您的個人資料。本隱私權政策說明我們如何收集、使用、儲存及保護您的個人資料，請您詳閱本政策內容。

2. 資料的收集與使用
本 APP 可能會收集以下類型的資料，以確保應用程式的正常運作及提升您的使用體驗：
- 個人身份資訊（如姓名、電子郵件）
- 健康相關資訊（如血壓、血糖記錄）
- 設備資訊（如裝置型號、操作系統）
- 使用行為數據（如功能使用情況、應用崩潰報告）

我們收集這些資料的目的包括但不限於：
- 提供及改善服務功能
- 保障應用程式的安全性與穩定性
- 進行數據分析，以優化使用者體驗

3. 資料的儲存與保護
我們採取適當的技術與管理措施來保護您的個人資料，防止未經授權的存取、使用或洩露：
- 我們使用加密技術來保護數據傳輸與存儲。
- 只有經授權的員工或合作夥伴可存取您的資料。
- 若您決定刪除帳戶，您的個人資料將依據法規適當處理。

4. 資料共享與第三方服務
我們不會在未經您同意的情況下向第三方出售、交易或轉讓您的個人資料。但在以下情況下，我們可能需要與第三方共享您的資料：
- 法律要求：若依法需要提供您的個人資料，我們將配合執法機構。
- 服務提供者：我們可能會使用第三方分析工具或雲端服務來提升應用程式效能。

5. 用戶權利
您有權查閱、更正或刪除您的個人資料，並可隨時撤回您的同意。如需行使您的權利，請透過應用程式內的設定或聯繫我們的客服。

6. 隱私權政策的變更
我們可能會根據業務需求或法律要求更新本隱私權政策，並在本 APP 內公告最新版本。

7. 聯絡我們
如對本隱私權政策有任何疑問，請聯繫我們的支援團隊：[email@example.com]。

本政策自發布之日起生效。
''',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("關閉"),
                                  ),
                                ],
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),
                value: _isPrivacyAccepted,
                onChanged: (bool? value) {
                  setState(() {
                    _isPrivacyAccepted = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registerUser,
                child: const Text("註冊"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

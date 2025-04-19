import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'personal_info_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false; // 用來控制密碼顯示與隱藏

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', uid);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login successful!")),
      );

      Navigator.pushReplacementNamed(context, '/');
    } on FirebaseAuthException catch (e) {
      String errorMessage = "登入失敗";
      if (e.code == 'user-not-found') {
        errorMessage = "找不到此使用者";
      } else if (e.code == 'wrong-password') {
        errorMessage = "密碼錯誤";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("登入失敗: ${e.toString()}")),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'https://www.googleapis.com/auth/fitness.activity.read',
          'https://www.googleapis.com/auth/fitness.heart_rate.read',
        ],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // 使用者取消登入
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      String uid = userCredential.user!.uid;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('uid', uid);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google 登入成功!")),
      );

      // ======= 加入這段請求 Google Fit 步數與心率 ==========
      final accessToken = googleAuth.accessToken;
      if (accessToken != null) {
        final stepResponse = await fetchStepCount(accessToken);
        print('步數資料：$stepResponse');

        final heartResponse = await fetchHeartRate(accessToken);
        print('心率資料：$heartResponse');
      }
      // =========================================

      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google 登入失敗: ${e.toString()}")),
      );
    }
  }

  Future<String> fetchStepCount(String accessToken) async {
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
          {"dataTypeName": "com.google.step_count.delta"}
        ],
        "bucketByTime": {"durationMillis": 86400000},
        "startTimeMillis": startTime,
        "endTimeMillis": endTime,
      }),
    );

    return response.body;
  }

  Future<String> fetchHeartRate(String accessToken) async {
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
          {"dataTypeName": "com.google.heart_rate.bpm"}
        ],
        "bucketByTime": {"durationMillis": 86400000},
        "startTimeMillis": startTime,
        "endTimeMillis": endTime,
      }),
    );

    return response.body;
  }



  // 忘記密碼功能
  void _forgotPassword() {
    TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("忘記密碼"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("請輸入您的 Email，我們將發送密碼重設信件。"),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "電子郵件"),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () async {
                String email = emailController.text.trim();
                if (email.isNotEmpty) {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("密碼重設信已發送，請檢查您的 Email。")),
                    );
                    Navigator.pop(context);
                  } on FirebaseAuthException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("錯誤: ${e.message}")),
                    );
                  }
                }
              },
              child: const Text("發送"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleProfileButton() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    if (uid != null && uid.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PersonalInfoPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("登入"),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _handleProfileButton,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "輸入電子郵件",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: "輸入密碼",
                border: const OutlineInputBorder(),
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
              obscureText: !_isPasswordVisible, // 控制密碼顯示
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: const Text("忘記密碼?"),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _login,
                child: const Text("登入"),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Image.asset(
                  'assets/google_logo.png', // 你要先在 assets 放一個 Google icon
                  height: 24.0,
                  width: 24.0,
                ),
                label: const Text("使用 Google 登入"),
                onPressed: _signInWithGoogle,
              ),
            ),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("還未註冊？"),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  child: const Text(
                    "立即註冊",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

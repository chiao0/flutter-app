import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'personal_info_page.dart';
import 'package:google_sign_in/google_sign_in.dart';



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
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = FirebaseAuth.instance.currentUser;
      await user?.reload(); // 重新載入使用者，避免狀態未更新
      user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        // ✅ Email 已驗證，繼續登入流程
        String uid = user.uid;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('uid', uid);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("登入成功！")),
        );

        Navigator.pushReplacementNamed(context, '/');
      } else {
        // ❌ Email 未驗證，登出使用者並提示
        await FirebaseAuth.instance.signOut();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("尚未驗證信箱"),
            content: const Text("請先至您的 Email 收信並完成驗證後，再重新登入。"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("我知道了"),
              ),
            ],
          ),
        );
      }
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
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

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

      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google 登入失敗: ${e.toString()}")),
      );
    }
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50), // 增加一點空間避免太貼近頂端
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
                obscureText: !_isPasswordVisible,
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
                    'assets/google_logo.png',
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
      ),

    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InviteCompanionScreen extends StatefulWidget {
  @override
  _InviteCompanionScreenState createState() => _InviteCompanionScreenState();
}

class _InviteCompanionScreenState extends State<InviteCompanionScreen> {
  String? personalInviteCode;
  String? enteredCode;
  final TextEditingController codeController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 取得目前使用者的個人邀請碼
  Future<void> _loadPersonalCode() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await _firestore.collection('user_profile').doc(currentUser.uid).get();
      setState(() {
        personalInviteCode = userDoc.get('personal_code');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPersonalCode();
  }

  // 當使用者輸入邀請碼並送出請求時
  Future<void> _sendInviteRequest() async {
    String code = codeController.text.trim();
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // 檢查輸入的邀請碼是否存在於 invitation_codes 資料表
    DocumentSnapshot inviteDoc = await _firestore.collection('invitation_codes').doc(code).get();
    if (!inviteDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("無效的邀請碼")),
      );
      return;
    }
    String ownerId = inviteDoc.get('owner_id');
    if (ownerId == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("不能使用自己的邀請碼")),
      );
      return;
    }
    // 建立邀請請求：寫入 companion_requests 資料表
    DocumentReference requestRef = await _firestore.collection('companion_requests').add({
      'inviter_id': ownerId,
      'invitee_id': currentUser.uid,
      'status': 'pending',
      'code_used': code,
      'requested_at': FieldValue.serverTimestamp(),
      'responded_at': null,
    });
    // 建立通知：通知邀請碼擁有者有新邀請請求
    await _firestore.collection('notifications').add({
      'recipient_id': ownerId,
      'sender_id': currentUser.uid,
      'type': 'companion_request',
      'content': '你有一筆新的陪伴邀請請求',
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("邀請送出"),
        content: Text("已送出陪伴請求，請等待對方確認"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
      ),
    );
    // 清除輸入欄位
    codeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("邀請陪伴者")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顯示個人邀請碼（供使用者分享）
            if (personalInviteCode != null)
              Text("你的個人邀請碼: $personalInviteCode",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            // 輸入邀請碼（作為被邀請者使用）
            TextField(
              controller: codeController,
              decoration: InputDecoration(labelText: "輸入邀請碼"),
              onChanged: (value) => enteredCode = value,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _sendInviteRequest,
              child: Text("送出邀請"),
            ),
          ],
        ),
      ),
    );
  }
}

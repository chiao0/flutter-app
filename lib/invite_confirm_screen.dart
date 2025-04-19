import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InviteConfirmScreen extends StatefulWidget {
  @override
  _InviteConfirmScreenState createState() => _InviteConfirmScreenState();
}

class _InviteConfirmScreenState extends State<InviteConfirmScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 使用 StreamBuilder 從 companion_requests 撈出當前使用者作為邀請碼擁有者收到的待處理請求
  Stream<QuerySnapshot> getPendingRequests() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return const Stream.empty();
    // 查詢 companion_requests 中 inviter_id 等於目前使用者 uid 且狀態為 pending 的請求
    return _firestore
        .collection('companion_requests')
        .where('inviter_id', isEqualTo: currentUser.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // 接受邀請，更新 companion_requests 狀態、更新 invitation_codes 的 is_used，
  // 建立 companion_relationships，發送通知，
  // 並更新 user_profile 資料表：
  //   - 對邀請者的文件: 加入 companions (被邀請者的 ID)
  //   - 對被邀請者的文件: 加入 is_companion_of (邀請者的 ID)
  Future<void> _acceptRequest(DocumentSnapshot requestDoc) async {
    try {
      String requestId = requestDoc.id;
      String inviteeId = requestDoc.get('invitee_id');
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // 更新 companion_requests 狀態
      await _firestore.collection('companion_requests').doc(requestId).update({
        'status': 'approved',
        'responded_at': FieldValue.serverTimestamp(),
      });

      // 取得請求中使用的邀請碼，並更新 invitation_codes 中的 is_used 欄位
      String codeUsed = requestDoc.get('code_used');
      await _firestore.collection('invitation_codes').doc(codeUsed).update({
        'is_used': true,
      });

      // 建立陪伴關係：寫入 companion_relationships 資料表
      await _firestore.collection('companion_relationships').add({
        'user_id': currentUser.uid,
        'companion_id': inviteeId,
        'established_at': FieldValue.serverTimestamp(),
        'permission_level': 'view', // 預設權限
        'shared_data_types': [], // 初始空清單
      });

      // 更新使用者資料表 (user_profile)
      // 對邀請者的文件，更新 companions 陣列，加上被邀請者 ID
      await _firestore.collection('user_profile').doc(currentUser.uid).update({
        'companions': FieldValue.arrayUnion([inviteeId]),
      });
      // 對被邀請者的文件，更新 is_companion_of 陣列，加上邀請者的 ID
      await _firestore.collection('user_profile').doc(inviteeId).update({
        'is_companion_of': FieldValue.arrayUnion([currentUser.uid]),
      });

      // 發送通知給接受邀請者
      await _firestore.collection('notifications').add({
        'recipient_id': inviteeId,
        'sender_id': currentUser.uid,
        'type': 'companion_request',
        'content': '你的陪伴請求已被接受',
        'is_read': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("已接受邀請")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("操作失敗: ${e.toString()}")),
      );
    }
  }

  // 拒絕邀請
  Future<void> _rejectRequest(DocumentSnapshot requestDoc) async {
    try {
      String requestId = requestDoc.id;
      String inviteeId = requestDoc.get('invitee_id');
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // 更新 companion_requests 狀態
      await _firestore.collection('companion_requests').doc(requestId).update({
        'status': 'rejected',
        'responded_at': FieldValue.serverTimestamp(),
      });

      // 發送通知給接受邀請者
      await _firestore.collection('notifications').add({
        'recipient_id': inviteeId,
        'sender_id': currentUser.uid,
        'type': 'companion_request',
        'content': '你的陪伴請求已被拒絕',
        'is_read': true,
        'created_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("已拒絕邀請")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("操作失敗: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("邀請確認")),
      body: StreamBuilder<QuerySnapshot>(
        stream: getPendingRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("錯誤: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final pendingRequests = snapshot.data!.docs;
          if (pendingRequests.isEmpty) {
            return Center(child: Text("目前無待處理的邀請"));
          }
          return ListView.builder(
            itemCount: pendingRequests.length,
            itemBuilder: (context, index) {
              var request = pendingRequests[index];
              return ListTile(
                leading: Icon(Icons.person),
                title: Text("邀請請求 ID: ${request.id}"),
                subtitle: Text(
                    "邀請者: ${request.get('inviter_id')}\n被邀請者: ${request.get('invitee_id')}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: Colors.green),
                      onPressed: () => _acceptRequest(request),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () => _rejectRequest(request),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

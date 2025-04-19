import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'invite_companion_screen.dart';
import 'invite_confirm_screen.dart';

class CompanionsListScreen extends StatelessWidget {
  const CompanionsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 取得目前登入使用者的 UID
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text("陪伴者列表")),
        body: Center(child: Text("請先登入")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("陪伴者列表")),
      body: StreamBuilder<QuerySnapshot>(
        // 從 companion_relationships 撈出目前使用者作為主帳號的陪伴關係
        stream: FirebaseFirestore.instance
            .collection('companion_relationships')
            .where('user_id', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("錯誤: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final relationshipDocs = snapshot.data!.docs;
          if (relationshipDocs.isEmpty) {
            return Center(child: Text("尚無陪伴者"));
          }
          return ListView.builder(
            itemCount: relationshipDocs.length,
            itemBuilder: (context, index) {
              // 取得該筆陪伴關係文件，並讀取 companion_id
              final relationshipData =
              relationshipDocs[index].data() as Map<String, dynamic>;
              final companionId = relationshipData['companion_id'];
              // 依據 companion_id 取得使用者資料（來自 user_profile 集合）
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('user_profile')
                    .doc(companionId)
                    .get(),
                builder: (context, companionSnapshot) {
                  if (companionSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      leading: Icon(Icons.person),
                      title: Text("讀取中..."),
                    );
                  }
                  if (!companionSnapshot.hasData ||
                      !companionSnapshot.data!.exists) {
                    return ListTile(
                      leading: Icon(Icons.person),
                      title: Text("未知陪伴者"),
                    );
                  }
                  final companionData =
                  companionSnapshot.data!.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: Icon(Icons.person),
                    title: Text(companionData['name'] ?? companionId),
                    subtitle: Text(companionData['email'] ?? ""),
                    onTap: () {
                      // TODO: 開啟健康數據頁面
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => InviteCompanionScreen()),
              );
            },
            tooltip: "邀請陪伴者",
            child: Icon(Icons.person_add),
          ),
          SizedBox(height: 16), // 兩個按鈕間的間距
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InviteConfirmScreen()),
              );
            },
            tooltip: "確認陪伴者",
            child: Icon(Icons.add_task),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class NotificationsPage extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final uid = authController.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("กรุณาเข้าสู่ระบบ")),
      );
    }

    final now = DateTime.now();
    final deadline = now.add(const Duration(days: 2)); // งานใกล้ถึงกำหนดภายใน 2 วัน

    print("📌 Query Notifications: uid=$uid, now=$now, deadline=$deadline");

    return Scaffold(
      appBar: AppBar(
        title: const Text("🔔 การแจ้งเตือน"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('uid', isEqualTo: uid)
            .where('endDate', isGreaterThanOrEqualTo: now) // ✅ เฉพาะงานยังไม่หมดอายุ
            .where('endDate', isLessThanOrEqualTo: deadline)
            .orderBy('endDate')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("⚠️ Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print("📭 ไม่มีงานใกล้ครบกำหนด");
            return const Center(
              child: Text("🎉 ไม่มีงานที่ใกล้ครบกำหนดใน 2 วัน"),
            );
          }

          final tasks = snapshot.data!.docs; // ใช้ตรงๆ ไม่ต้อง sort

          print("✅ ดึงได้ ${tasks.length} งาน");

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = tasks[index].data() as Map<String, dynamic>;
              final endDate = (task['endDate'] as Timestamp).toDate();

              print("➡️ Task: ${task['title']} | endDate=$endDate");

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orangeAccent, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled, color: Colors.orange, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title'] ?? "ไม่มีชื่อ",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "ครบกำหนด: ${endDate.toString().substring(0, 16)}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
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

import 'package:ai_task_project_manager/pages/setting/setting_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_controller.dart';
import '../../controllers/dashboard_controller.dart';

// สีหลักของธีม
const Color primaryColor = Color(0xFF3B82F6);

class HomePage extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();
  final DashboardController dashboardController =
      Get.find<DashboardController>();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = authController.currentUser?.uid;
    if (uid == null) {
      Future.microtask(() => Get.offAllNamed('/login'));
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'AI Task Manager',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'ออกจากระบบ',
            onPressed: () => _confirmSignOut(),
          ),
          IconButton(
            onPressed: () => Get.toNamed('/settings'),
            icon: Icon(Icons.settings, color: Colors.white),
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("ไม่พบข้อมูลผู้ใช้"));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final name = userData['name'] ?? 'ผู้ใช้งาน';
          final email = userData['email'] ?? 'ไม่มีข้อมูล';
          final photoUrl = userData['photoUrl'] ?? '';

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // โปรไฟล์
              _buildProfileCard(context, name, email, photoUrl),
              const SizedBox(height: 20),
              // Quick Stats
              _buildQuickStats(),
              const SizedBox(height: 20),
              // Grid Menu
              _buildGridMenu(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    String name,
    String email,
    String photoUrl,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Obx(
              () => CircleAvatar(
                radius: 40,
                backgroundImage: authController.photoURL.value.isNotEmpty
                    ? NetworkImage(authController.photoURL.value)
                    : const AssetImage("assets/default_avatar.png")
                          as ImageProvider,
              ),
            ),
            const Text('kuy'),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "สวัสดี,",
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Obx(
                    () => Text(
                      authController.name.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Obx(() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statusCard('Todo', dashboardController.todoCount.value, Colors.grey),
          _statusCard(
            'In Progress',
            dashboardController.inProgressCount.value,
            Colors.orange,
          ),
          _statusCard(
            'Done',
            dashboardController.doneCount.value,
            Colors.green,
          ),
        ],
      );
    });
  }

  Widget _statusCard(String title, int count, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridMenu() {
    final List<Map<String, dynamic>> menus = [
      {
        'icon': Icons.dashboard_rounded,
        'title': 'Dashboard',
        'route': '/dashboard',
      },
      {'icon': Icons.list_alt_rounded, 'title': 'Task List', 'route': '/tasks'},
      {
        'icon': Icons.smart_toy_rounded,
        'title': 'AI Import',
        'route': '/ai-import',
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'Analytics',
        'route': '/analytic',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: menus.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final menu = menus[index];
        return GestureDetector(
          onTap: () => Get.toNamed(menu['route']),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(menu['icon'], size: 36, color: primaryColor),
                const SizedBox(height: 8),
                Text(
                  menu['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmSignOut() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "ออกจากระบบ",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: const Text(
          "คุณแน่ใจหรือไม่ว่าต้องการออกจากระบบ?",
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              "ยกเลิก",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              authController.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              "ออกจากระบบ",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

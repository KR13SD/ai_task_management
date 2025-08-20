import 'package:ai_task_project_manager/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingPage extends StatelessWidget {
  SettingPage({super.key});

  final AuthController _authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "การตั้งค่า",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildSectionTitle("บัญชีผู้ใช้"),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.person_outline_rounded,
                title: "ข้อมูลส่วนตัว",
                subtitle: "จัดการข้อมูลโปรไฟล์ของคุณ",
                onTap: () => Get.toNamed('/profile-detail'),
                iconColor: Colors.blue,
                iconBg: Colors.blue.shade50,
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.lock_outline_rounded,
                title: "เปลี่ยนรหัสผ่าน",
                subtitle: "อัปเดตรหัสผ่านเพื่อความปลอดภัย",
                onTap: () => Get.toNamed('/change-password'),
                iconColor: Colors.orange,
                iconBg: Colors.orange.shade50,
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.logout_rounded,
                title: "ออกจากระบบ",
                subtitle: "ออกจากบัญชีผู้ใช้ปัจจุบัน",
                onTap: () => _showLogoutDialog(),
                iconColor: Colors.red,
                iconBg: Colors.red.shade50,
              ),
            ]),

            const SizedBox(height: 24),

            // Support Section
            _buildSectionTitle("การสนับสนุน"),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.support_agent_rounded,
                title: "ติดต่อฝ่ายสนับสนุน",
                subtitle: "ได้รับความช่วยเหลือและแก้ไขปัญหา",
                onTap: () => Get.toNamed('/contact-support'),
                iconColor: Colors.green,
                iconBg: Colors.green.shade50,
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.info_outline_rounded,
                title: "เกี่ยวกับแอป",
                subtitle: "ข้อมูลเวอร์ชันและนโยบาย",
                onTap: () => Get.toNamed('/about-app'),
                iconColor: Colors.purple,
                iconBg: Colors.purple.shade50,
              ),
            ]),

            const SizedBox(height: 24),

            // Additional Settings Section
            _buildSectionTitle("การตั้งค่าอื่นๆ"),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _buildSettingsTile(
                icon: Icons.notifications_outlined,
                title: "การแจ้งเตือน",
                subtitle: "จัดการการแจ้งเตือนแอป",
                onTap: () {
                  // Add notification settings navigation
                },
                iconColor: Colors.red,
                iconBg: Colors.red.shade50,
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.language_rounded,
                title: "ภาษา",
                subtitle: "เลือกภาษาที่ต้องการใช้",
                onTap: () {
                  // Add language settings navigation
                },
                iconColor: Colors.indigo,
                iconBg: Colors.indigo.shade50,
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.dark_mode_outlined,
                title: "ธีมแอป",
                subtitle: "เปลี่ยนรูปแบบการแสดงผล",
                onTap: () {
                  // Add theme settings navigation
                },
                iconColor: Colors.grey[700]!,
                iconBg: Colors.grey.shade100,
              ),
            ]),

            const SizedBox(height: 24),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
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
              _authController.signOut();
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


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color iconColor,
    required Color iconBg,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: Colors.grey[100],
    );
  }
}

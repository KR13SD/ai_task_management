import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';

const Color primaryColor = Color(0xFF1E3A8A);

class LoginPage extends StatelessWidget {
  final AuthController c = Get.put(AuthController());

  LoginPage({super.key});

  // ข้อมูล test user
  final Map<String, String> testUser1 = {
    'email': 'arjin@momomail.coco',
    'password': '111111',
  };
  final Map<String, String> testUser2 = {
    'email': 'aka@mail.com',
    'password': '123456',
  };

  void fillTestUser(Map<String, String> user) {
    c.loginEmailController.text = user['email']!;
    c.loginPasswordController.text = user['password']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'AI TASK MANAGEMENT',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Obx(
            () => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'เข้าสู่ระบบ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 40),
                // Email
                TextField(
                  controller: c.loginEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: primaryColor,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Password
                TextField(
                  controller: c.loginPasswordController,
                  obscureText: c.isPasswordHidden.value,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: primaryColor,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        c.isPasswordHidden.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: primaryColor,
                      ),
                      onPressed: c.togglePasswordVisibility,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Login button
                c.isLoading.value
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : ElevatedButton(
                        onPressed: c.login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                const SizedBox(height: 16),
                // Quick Login buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () => fillTestUser(testUser1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      child: const Text('Test User 1'),
                    ),
                    ElevatedButton(
                      onPressed: () => fillTestUser(testUser2),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                      child: const Text('Test User 2'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Get.toNamed('/register');
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'ยังไม่มีบัญชี? ',
                      style: TextStyle(
                        fontFamily: GoogleFonts.kanit().fontFamily,
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'ลงทะเบียน',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/auth_controller.dart';

const Color primaryColor = Color(0xFF1E3A8A);

class RegisterPage extends StatelessWidget {
  final AuthController c = Get.find<AuthController>();

  RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'สร้างบัญชีผู้ใช้',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,

        iconTheme: const IconThemeData(color: Colors.white),
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
                  'ลงทะเบียน',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: c.nameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อ-นามสกุล',
                    prefixIcon: const Icon(
                      Icons.person_outline,
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

                TextField(
                  controller: c.emailController,
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

                TextField(
                  controller: c.passwordController,
                  obscureText: c.isPasswordHidden.value,
                  decoration: InputDecoration(
                    labelText: 'Password (อย่างน้อย 6 ตัว)',
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

                c.isLoading.value
                    ? const Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      )
                    : ElevatedButton(
                        onPressed: c.register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'มีบัญชีอยู่แล้ว? ',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                        fontFamily: GoogleFonts.kanit().fontFamily,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: 'กลับไปหน้า Login',
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

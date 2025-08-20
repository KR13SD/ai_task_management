import 'package:flutter/material.dart';
import 'package:ai_task_project_manager/controllers/auth_controller.dart';
import 'package:get/get.dart';

class ChangePasswordPage extends GetView<AuthController> {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF0F0F0F) 
          : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          "Change Password",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: theme.primaryColor,
            ),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Section
                  Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.primaryColor.withOpacity(0.8),
                                theme.primaryColor,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.security_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Secure Your Account",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Update your password to keep your account safe and secure",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark 
                                ? Colors.white.withOpacity(0.7) 
                                : const Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Fields
                  _buildModernTextField(
                    controller: controller.currentPasswordController,
                    isObscured: controller.isCurrentPasswordHidden,
                    label: "Current Password",
                    hint: "Enter your current password",
                    icon: Icons.lock_outline_rounded,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your current password';
                      }
                      return null;
                    },
                    isDark: isDark,
                    theme: theme,
                  ),

                  const SizedBox(height: 20),

                  _buildModernTextField(
                    controller: controller.newPasswordController,
                    isObscured: controller.isNewPasswordHidden,
                    label: "New Password",
                    hint: "Enter your new password",
                    icon: Icons.lock_person_outlined,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                    isDark: isDark,
                    theme: theme,
                  ),

                  const SizedBox(height: 20),

                  _buildModernTextField(
                    controller: controller.ConfirmNewPasswordController,
                    isObscured: controller.isConfirmPasswordHidden,
                    label: "Confirm New Password",
                    hint: "Re-enter your new password",
                    icon: Icons.verified_user_outlined,
                    validator: (value) {
                      if (value != controller.newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    isDark: isDark,
                    theme: theme,
                  ),

                  const SizedBox(height: 32),

                  // Security Tips Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF1A1A1A) 
                          : Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.tips_and_updates_rounded,
                              color: theme.primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Password Tips",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPasswordTip("Use at least 8 characters", isDark),
                        _buildPasswordTip("Include numbers and symbols", isDark),
                        _buildPasswordTip("Mix uppercase and lowercase letters", isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Update Button
                  Obx(() {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: controller.isLoading.value
                          ? Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.primaryColor,
                                    theme.primaryColor.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    if (_formKey.currentState!.validate()) {
                                      controller.updatePassword();
                                    }
                                  },
                                  child: Container(
                                    height: 56,
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.security_update_good_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Update Password',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    );
                  }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required RxBool isObscured,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              obscureText: isObscured.value,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark 
                      ? Colors.white.withOpacity(0.5) 
                      : const Color(0xFF9CA3AF),
                  fontSize: 16,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isObscured.value 
                          ? Icons.visibility_off_rounded 
                          : Icons.visibility_rounded,
                      color: isDark 
                          ? Colors.white.withOpacity(0.7) 
                          : const Color(0xFF6B7280),
                      size: 20,
                    ),
                  ),
                  onPressed: () => isObscured.toggle(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark 
                        ? Colors.white.withOpacity(0.1) 
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark 
                        ? Colors.white.withOpacity(0.1) 
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: theme.primaryColor,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDark 
                    ? const Color(0xFF1A1A1A) 
                    : Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
              ),
              validator: validator,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPasswordTip(String tip, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: isDark 
                ? Colors.white.withOpacity(0.7) 
                : const Color(0xFF6B7280),
          ),
          const SizedBox(width: 8),
          Text(
            tip,
            style: TextStyle(
              fontSize: 14,
              color: isDark 
                  ? Colors.white.withOpacity(0.7) 
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
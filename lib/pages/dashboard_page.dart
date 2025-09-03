import 'package:ai_task_project_manager/pages/task_detail_page.dart';
import 'package:ai_task_project_manager/pages/task_view_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../controllers/dashboard_controller.dart';
import '../../models/task_model.dart';

const Color primaryColor = Color(0xFF3B82F6);

class DashboardPage extends StatelessWidget {
  final DashboardController controller = Get.find<DashboardController>();

  DashboardPage({super.key});

  // ฟังก์ชันสำหรับกำหนดสีตาม Priority
  Map<String, dynamic> _getPriorityColors(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return {
          'gradient': [Colors.red.shade400, Colors.red.shade600],
          'bg': Colors.red.shade50,
          'fg': Colors.red.shade700,
          'shadow': Colors.red.shade200,
          'icon': Icons.priority_high,
        };
      case 'medium':
        return {
          'gradient': [Colors.orange.shade400, Colors.orange.shade600],
          'bg': Colors.orange.shade50,
          'fg': Colors.orange.shade700,
          'shadow': Colors.orange.shade200,
          'icon': Icons.remove,
        };
      case 'low':
        return {
          'gradient': [Colors.green.shade400, Colors.green.shade600],
          'bg': Colors.green.shade50,
          'fg': Colors.green.shade700,
          'shadow': Colors.green.shade200,
          'icon': Icons.keyboard_arrow_down,
        };
      default:
        return {
          'gradient': [Colors.grey.shade400, Colors.grey.shade600],
          'bg': Colors.grey.shade100,
          'fg': Colors.grey.shade700,
          'shadow': Colors.grey.shade200,
          'icon': Icons.horizontal_rule,
        };
    }
  }

  List<TaskModel> _sortTasksByPriority(List<TaskModel> tasks) {
    final priorityOrder = {"high": 1, "medium": 2, "low": 3};

    tasks.sort((a, b) {
      final aPriority = priorityOrder[a.priority.toLowerCase()] ?? 4;
      final bPriority = priorityOrder[b.priority.toLowerCase()] ?? 4;
      return aPriority.compareTo(bPriority);
    });

    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 3,
            ),
          );
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildStatsCards(),
                    const SizedBox(height: 32),
                    _buildTaskListSection(
                      context: context,
                      title: "todaytasks".tr,
                      tasks: controller.tasksToday,
                      emptyMessage: "notasksfortoday".tr,
                      icon: Icons.today,
                      gradientColors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildTaskListSection(
                      context: context,
                      title: "taskincoming(3days)".tr,
                      tasks: controller.tasksUpcoming,
                      emptyMessage: "noupcomingtasks".tr,
                      icon: Icons.upcoming,
                      gradientColors: [
                        Colors.purple.shade400,
                        Colors.purple.shade600,
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildTaskListSection(
                      context: context,
                      title: "taskoverdue".tr,
                      tasks: controller.tasksOverdue,
                      emptyMessage: "nooverduetasks".tr,
                      icon: Icons.schedule,
                      gradientColors: [
                        Colors.red.shade400,
                        Colors.red.shade600,
                      ],
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
  return AppBar(
    title: Text(
      'dashboard'.tr,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 24,
        color: Colors.white, // สีขาวให้อ่านชัดบน gradient
      ),
    ),
    leading: IconButton(
      onPressed: () => Get.back(),
      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
    ),
    foregroundColor: Colors.white,
    elevation: 0,
    flexibleSpace: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    ),
  );
}


  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: "Today",
            count: controller.tasksToday.length,
            icon: Icons.today,
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: "Upcoming",
            count: controller.tasksUpcoming.length,
            icon: Icons.upcoming,
            colors: [Colors.purple.shade400, Colors.purple.shade600],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: "Overdue",
            count: controller.tasksOverdue.length,
            icon: Icons.schedule,
            colors: [Colors.red.shade400, Colors.red.shade600],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required List<Color> colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      heroTag: 'importAI',
      backgroundColor: primaryColor,
      onPressed: () => Get.toNamed('/ai-import'),
      icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      label: const Text(
        'AI Import',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      elevation: 8,
    );
  }

  Widget _buildTaskListSection({
    required BuildContext context,
    required String title,
    required List<TaskModel> tasks,
    required String emptyMessage,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    final sortedTasks = _sortTasksByPriority(List.from(tasks));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tasks.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        tasks.isEmpty
            ? _buildEmptyState(emptyMessage)
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedTasks.length,
                itemBuilder: (context, index) {
                  final task = sortedTasks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _taskCard(task),
                  );
                },
              ),
      ],
    );
  }

  Widget _taskCard(TaskModel task) {
    final colors = _getPriorityColors(task.priority);
    final gradientColors = colors['gradient'] as List<Color>;
    final bgColor = colors['bg'] as Color;
    final fgColor = colors['fg'] as Color;
    final shadowColor = colors['shadow'] as Color;
    final priorityIcon = colors['icon'] as IconData;
    final locale = Get.locale?.languageCode ?? 'en';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Get.to(() => TaskViewPage(task: task), arguments: task.id);
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: gradientColors,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${DateFormat('d MMM', locale).format(task.startDate)} - '
                                '${DateFormat('d MMM yyyy', locale).format(task.endDate)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildAdvancedPriorityChip(
                      task.priority,
                      priorityIcon,
                      gradientColors,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedPriorityChip(
    String priority,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            priority.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade600],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

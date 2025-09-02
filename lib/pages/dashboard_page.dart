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
  Map<String, Color> _getPriorityColors(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return {'bg': Colors.red.shade50, 'fg': Colors.red.shade800};
      case 'medium':
        return {'bg': Colors.orange.shade50, 'fg': Colors.orange.shade800};
      case 'low':
        return {'bg': Colors.green.shade50, 'fg': Colors.green.shade800};
      default:
        return {'bg': Colors.grey.shade100, 'fg': Colors.grey.shade800};
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'dashboard'.tr,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _buildTaskListSection(
              context: context,
              title: "todaytasks".tr,
              tasks: controller.tasksToday,
              emptyMessage: "notasksfortoday".tr,
            ),
            const SizedBox(height: 24),
            _buildTaskListSection(
              context: context,
              title: "taskincoming(3days)".tr,
              tasks: controller.tasksUpcoming,
              emptyMessage: "noupcomingtasks".tr,
            ),
            _buildTaskListSection(
              context: context,
              title: "taskoverdue".tr,
              tasks: controller.tasksOverdue,
              emptyMessage: "nooverduetasks".tr,
            ),
          ],
        );
      }),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'importAI',
          backgroundColor: primaryColor,
          onPressed: () => Get.toNamed('/ai-import'),
          child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
          tooltip: 'นำเข้าด้วย AI',
        ),
      ],
    );
  }

  Widget _buildTaskListSection({
    required BuildContext context,
    required String title,
    required List<TaskModel> tasks,
    required String emptyMessage,
  }) {
    final sortedTasks = _sortTasksByPriority(List.from(tasks));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
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

  // Widget สำหรับแสดงการ์ด Task ที่ปรับปรุงสีตาม Priority
  Widget _taskCard(TaskModel task) {
    final colors = _getPriorityColors(task.priority);
    final bgColor = colors['bg']!;
    final fgColor = colors['fg']!;
    final locale = Get.locale?.languageCode ?? 'en';

    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: fgColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Get.to(TaskViewPage(task: task), arguments: task.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: fgColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildPriorityChip(task.priority),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: fgColor.withOpacity(0.2)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: fgColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('d MMM', locale).format(task.startDate)} - '
                        '${DateFormat('d MMM yyyy', locale).format(task.endDate)}',
                        style: TextStyle(
                          color: fgColor.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.chevron_right, color: fgColor.withOpacity(0.7)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    final colors = _getPriorityColors(priority);
    final fgColor = colors['fg']!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fgColor.withOpacity(0.5)),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

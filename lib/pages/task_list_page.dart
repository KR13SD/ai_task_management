import 'package:ai_task_project_manager/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../controllers/dashboard_controller.dart';
import '../../models/task_model.dart';
import 'task_detail_page.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final DashboardController controller = Get.find<DashboardController>();
  final formattedDate = ''.obs;

  @override
  void initState() {
    super.initState();
    _initDateFormatting();
    
    final service = Get.find<LocalizationService>();
    ever(service.currentLocale, (_) => _initDateFormatting());
  }

  Future<void> _initDateFormatting() async {
    final locale = Get.locale?.toString() ?? 'th_TH';
    await initializeDateFormatting(locale, null);
    _updateFormattedDate(DateTime.now());
  }

  void _updateFormattedDate(DateTime date) {
    final locale = Get.locale?.toString() ?? 'th_TH';
    final formatter = DateFormat('dd MMM yyyy', locale);
    formattedDate.value = formatter.format(date);
  }

  final List<Map<String, Object>> statusOptions = [
    {
      'key': 'all',
      'label': 'all'.tr,
      'icon': Icons.list_alt,
      'color': Colors.blue,
    },
    {
      'key': 'todo',
      'label': 'pending'.tr,
      'icon': Icons.pending_actions,
      'color': Colors.grey,
    },
    {
      'key': 'in_progress',
      'label': 'inprogress'.tr,
      'icon': Icons.work,
      'color': Colors.orange,
    },
    {
      'key': 'done',
      'label': 'completed'.tr,
      'icon': Icons.task_alt,
      'color': Colors.green,
    },
    {
      'key': 'overdue',
      'label': 'overdue'.tr,
      'icon': Icons.warning,
      'color': Colors.red,
    },
  ];

  String selectedStatus = 'all';

  List<TaskModel> filteredTasks(String status) {
    final allTasks = controller.allTasks;

    switch (status) {
      case 'todo':
        return allTasks.where((t) => t.status.toLowerCase() == 'todo').toList();
      case 'in_progress':
        return allTasks
            .where((t) => t.status.toLowerCase() == 'in_progress')
            .toList();
      case 'done':
        return allTasks.where((t) => t.status.toLowerCase() == 'done').toList();
      case 'overdue':
        final now = DateTime.now();
        return allTasks
            .where(
              (t) =>
                  t.status.toLowerCase() != 'done' && t.endDate.isBefore(now),
            )
            .toList();
      case 'all':
      default:
        return allTasks;
    }
  }

  List<TaskModel> _sortTasksByStatus(List<TaskModel> tasks) {
  final now = DateTime.now();
  const priority = {
    'in_progress': 1,
    'todo': 2,
    'overdue': 3,
    'done': 4,
  };

  return tasks..sort((a, b) {
    String statusA = a.status.toLowerCase();
    String statusB = b.status.toLowerCase();

    // ตรวจสอบ overdue
    if (statusA != 'done' && a.endDate.isBefore(now)) statusA = 'overdue';
    if (statusB != 'done' && b.endDate.isBefore(now)) statusB = 'overdue';

    return (priority[statusA] ?? 99).compareTo(priority[statusB] ?? 99);
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.green[300],
        foregroundColor: Colors.white,
        title: Text('tasklist'.tr),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: statusOptions.length,
                itemBuilder: (context, index) {
                  final option = statusOptions[index];
                  final String key = option['key'] as String;
                  final String label = option['label'] as String;
                  final IconData icon = option['icon'] as IconData;
                  final Color color = option['color'] as Color;
                  final isSelected = selectedStatus == key;

                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: isSelected ? Colors.white : color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[700],
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      selectedColor: color,
                      backgroundColor: Colors.white,
                      elevation: isSelected ? 4 : 1,
                      shadowColor: color.withOpacity(0.3),
                      onSelected: (_) {
                        setState(() => selectedStatus = key);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          Obx(() {
            if (controller.isLoading.value) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('loading'.tr),
                    ],
                  ),
                ),
              );
            }

            final tasks = _sortTasksByStatus(filteredTasks(selectedStatus));

            if (tasks.isEmpty) {
              return SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'notasksinthislist'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'startcreatetask'.tr,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final task = tasks[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 6,
                    bottom: index == tasks.length - 1
                        ? 100
                        : 6, // เพิ่มระยะห่างด้านล่างสำหรับ card สุดท้าย
                  ),
                  child: _buildModernTaskCard(task),
                );
              }, childCount: tasks.length),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/addtasks'),
        backgroundColor: Colors.green[300],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'addtask'.tr,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildModernTaskCard(TaskModel task) {
    final isDone = task.status.toLowerCase() == 'done';
    final isOverdue = !isDone && task.endDate.isBefore(DateTime.now());

    // กำหนดสีและไอคอนตามสถานะ
    Color statusColor;
    Color cardColor;
    IconData statusIcon;

    switch (task.status.toLowerCase()) {
      case 'todo':
        statusColor = Colors.grey[600]!;
        cardColor = Colors.grey[50]!;
        statusIcon = Icons.pending_actions;
        break;
      case 'in_progress':
        statusColor = Colors.orange[600]!;
        cardColor = Colors.orange[50]!;
        statusIcon = Icons.work;
        break;
      case 'done':
        statusColor = Colors.green[600]!;
        cardColor = Colors.green[50]!;
        statusIcon = Icons.task_alt;
        break;
      default:
        statusColor = Colors.grey[600]!;
        cardColor = Colors.white;
        statusIcon = Icons.help_outline;
    }

    if (isOverdue) {
      statusColor = Colors.red[600]!;
      cardColor = Colors.red[50]!;
    }

    return Card(
      elevation: 2,
      shadowColor: statusColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.2), width: 1),
      ),
      color: cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Get.to(() => TaskDetailPage(task: task)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(statusIcon, size: 20, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusLabel(task.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Date information
              Row(
                children: [
                  Expanded(
                    child: _buildDateInfo(
                      'startdate'.tr,
                      task.startDate,
                      Icons.play_arrow,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateInfo(
                      'duedate'.tr,
                      task.endDate,
                      Icons.flag,
                      isOverdue ? Colors.red : Colors.blue,
                    ),
                  ),
                ],
              ),

              if (isOverdue) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red[600], size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'out of date'.tr,
                        style: TextStyle(
                          color: Colors.red[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isDone) ...[
                    _buildActionButton(
                      icon: Icons.play_arrow,
                      color: Colors.orange,
                      onPressed: () => _confirmUpdateStatus(task),
                      tooltip: 'starttask'.tr,
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.check,
                      color: Colors.green,
                      onPressed: () => _confirmMarkDone(task),
                      tooltip: 'endtask'.tr,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    onPressed: () => _confirmDelete(task),
                    tooltip: 'deletetask'.tr,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateInfo(
    String label,
    DateTime date,
    IconData icon,
    Color color,
  ) {
      final locale = Get.locale?.toString() ?? 'en_US';
      final formatter = DateFormat('dd MMM yyyy', locale);

      return Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                formatter.format(date),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color, size: 20),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'todo':
        return 'pending'.tr;
      case 'in_progress':
        return 'inprogress'.tr;
      case 'done':
        return 'completed'.tr;
      default:
        return status;
    }
  }

  void _confirmMarkDone(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.task_alt, color: Colors.green[600]),
            ),
            const SizedBox(width: 12),
            Text('confirmchangestatus'.tr),
          ],
        ),
        content: Text('dialogconfirmstatus'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updateTaskStatus(task.id, 'done');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline, color: Colors.red[600]),
            ),
            const SizedBox(width: 12),
            Text('comfirmdelete'.tr),
          ],
        ),
        content: Text('dialogconfirmdelete'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteTask(task.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }

  void _confirmUpdateStatus(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.work, color: Colors.orange[600]),
            ),
            const SizedBox(width: 12),
            Text('starttask'.tr),
          ],
        ),
        content: Text('confirmchangestatus'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              controller.updateTaskStatus(task.id, 'in_progress');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('confirm'.tr),
          ),
        ],
      ),
    );
  }
}
